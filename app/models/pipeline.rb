class Pipeline
  attr_accessor :messages
  attr_accessor :saved_messages

  def process(address, message)
    @address = address
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @message = message
    @messages = Hash.new{|k, v| k[v] = []}
    @saved_messages = Hash.new{|k, v| k[v] = []}

    node = Parser.parse(message, self, :parse_signup_and_join => !current_user)

    # Remove Node part and put first letter in downcase
    node_name = node.class.name[0 ... -4].tableize.singularize
    send "process_#{node_name}", node
  end

  def process_signup(node)
    return reply "This device already belongs to other user. To dettach it send: bye" if current_channel

    password = PasswordGenerator.new_password

    login = node.suggested_login
    index = 2
    while User.find_by_login(login)
      login = "#{node.suggested_login}#{index}"
      index += 1
    end

    if @address2.integer?
      user = User.find_by_login_and_created_from_invite @address2, true
      if user
        user.login = login
        user.display_name = node.display_name
        user.password = password
        user.created_from_invite = false
        user.save!
      end
    end

    if not user
      user = User.create! :login => login, :password => password, :display_name => node.display_name
    end

    channel = create_channel_for user
    reply "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    reply "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"

    if node.group
      process_join node
    else
      reply "To send messages to a group, you must first join one. Send: join GROUP"
    end
  end

  def process_login(node)
    user = User.find_by_login_and_password node.login, node.password
    return reply "Invalid login" unless user

    if current_channel
      current_channel.user = user
      current_channel.save!
    else
      channel = create_channel_for user
    end

    reply "Hello #{user.display_name}. When you want to remove this device send: bye"
  end

  def process_logout(node)
    return not_logged_in unless current_channel

    current_channel.destroy

    reply "#{current_channel.user.display_name}, this device has been removed from your account."
  end

  def process_create_group(node)
    return not_logged_in unless current_user

    if Group.find_by_alias(node.alias)
      return reply "The group #{node.alias} already exists. Please specify another alias."
    end

    group = Group.create! :alias => node.alias, :name => node.name || node.alias
    Membership.create! :user => current_user, :group => group, :role => :owner

    reply "Group '#{group.alias}' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: #{group.alias} +PHONE_NUMBER"
  end

  def process_off(node)
    return if current_channel.status == :off

    current_channel.status = :off
    current_channel.save!

    reply "GeoChat Alerts. You sent '#off' and we have turned off SMS updates to this phone. Reply with START to turn back on. Questions email support@instedd.org."
  end

  def process_on(node)
    if current_channel.status != :on
      current_channel.status = :on
      current_channel.save!
    end

    reply "You sent '#on' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  def process_invite(node)
    if node.group
      group = Group.find_by_alias node.group
      if !group
        group = Group.find_by_alias node.users.first
        if group
          node.users = [node.group]
        else
          node.users.insert 0, node.group
        end
      end
    end

    group = current_user.default_group unless group

    if not group
      groups = current_user.groups
      if groups.empty?
        return reply "You don't belong to any group yet. To join a group send: join groupalias"
      elsif groups.length == 1
        group = groups.first
      else
        return reply "You must specify a group to invite the users to, or set a default group."
      end
    end

    sent = []

    node.users.each do |name|
      user = User.find_by_login name
      if !user && name.integer?
        user = User.find_by_mobile_number name
      end

      if user
        invite = Invite.find_by_group_and_user group, user
        if invite
          if invite.user_accepted
            user.join group
            send_message_to_user user, "Welcome #{user.login} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
            invite.destroy
          end
        else
          Invite.create! :group => group, :user => user, :admin_accepted => current_user.is_owner_of(group)
          send_message_to_user user, "#{current_user.login} has invited you to group #{group.alias}. You can join by sending: join #{group.alias}"
        end
        sent << name
      else
        if name.integer?
          user = User.create! :login => name, :created_from_invite => true
          Invite.create! :group => group, :user => user, :admin_accepted => current_user.is_owner_of(group)
          send_message_to_address "sms://#{name}", "Welcome to GeoChat's group #{group.alias}. Tell us your name and join the group by sending: YOUR_NAME join #{group.alias}"
          sent << name
        else
          reply "Could not find a registered user '#{name}' for your invitation."
        end
      end
    end

    reply "Invitation/s sent to #{sent.join(', ')}" if sent.present?
  end

  def process_join(node)
    group = Group.find_by_alias node.group
    if group.requires_aproval_to_join
      invite = Invite.find_by_group_and_user group, current_user
      if invite
        if invite.admin_accepted
          invite.destroy

          current_user.join group
          reply "Welcome #{current_user.display_name} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
        else
          invite.user_accepted = true
          invite.save!

          send_message_to_group_owners group, "An invitation is pending for approval. To approve it send: invite #{group.alias} #{current_user.login}"
          reply "Group #{group.alias} requires approval to join by an Administrator. We will let you know when you can start sending messages."
        end
      else
        Invite.create! :user => current_user, :group => group, :user_accepted => true
        send_message_to_group_owners group, "An invitation is pending for approval. To approve it send: invite #{group.alias} #{current_user.login}"
        reply "Group #{group.alias} requires approval to join by an Administrator. We will let you know when you can start sending messages."
      end
    else
      invite = Invite.find_by_group_and_user group, current_user
      invite.destroy if invite

      current_user.join group
      reply "Welcome #{current_user.display_name} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    end
  end

  def process_my(node)
    case node.key
    when MyNode::Group
      group = Group.find_by_alias node.value
      if group
        current_user.default_group_id = group.id
        current_user.save!
      end
    end
  end

  def process_owner(node)
    user = User.find_by_login node.user

    group = current_user.default_group

    if not group
      groups = current_user.groups
      if groups.empty?
        # TODO
        # return reply "You don't belong to any group yet. To join a group send: join groupalias"
      elsif groups.length == 1
        group = groups.first
      else
        # TODO
        # return reply "You must specify a group to invite the users to, or set a default group."
      end
    end

    user.make_owner_of group
  end

  def process_message(node)
    group = current_user.default_group

    if not group
      groups = current_user.groups
      if groups.empty?
        # TODO
        # return reply "You don't belong to any group yet. To join a group send: join groupalias"
      elsif groups.length == 1
        group = groups.first
      else
        # TODO
        # return reply "You must specify a group to invite the users to, or set a default group."
      end
    end

    send_message_to_group group, "#{current_user.login}: #{node.body}"
  end

  def get_target(name)
    if current_user
      group = current_user.groups.find_by_alias(name)
      return GroupTarget.new(name, group) if group
    end

    nil
  end

  private

  def not_logged_in
    reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def reply(msg)
    @messages[@address] << msg
  end

  def send_message_to_group(group, msg)
    group.users.reject{|x| x.id == current_user.id}.each do |user|
      send_message_to_user user, msg
    end
  end

  def send_message_to_group_owners(group, msg)
    group.owners.each do |user|
      send_message_to_user user, msg
    end
  end

  def send_message_to_user(user, msg)
    user.channels.each do |channel|
      send_message_to_channel channel, msg
    end
  end

  def send_message_to_channel(channel, msg)
    send_message_to_address channel.full_address, msg
  end

  def send_message_to_address(address, msg)
    @messages[address] << msg
  end

  def create_channel_for(user)
    Channel.create! :protocol => @protocol, :address => @address2, :user => user, :status => :on
  end

  def current_channel
    @channel ||= Channel.find_by_protocol_and_address @protocol, @address2
  end

  def current_user
    current_channel.try(:user)
  end
end
