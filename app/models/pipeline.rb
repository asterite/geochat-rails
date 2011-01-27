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

    login = User.find_suitable_login node.suggested_login
    password = PasswordGenerator.new_password

    if @address2.integer?
      user = User.find_by_login_and_created_from_invite @address2, true
      if user
        user.attributes = {:login => login, :display_name => node.display_name, :password => password, :created_from_invite => false}
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

    group = current_user.create_group :alias => node.alias, :name => (node.name || node.alias), :chatroom => !node.nochat

    reply "Group '#{group.alias}' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: #{group.alias} +PHONE_NUMBER"
  end

  def process_off(node)
    return not_logged_in unless current_user
    return if current_channel.status == :off

    current_channel.status = :off
    current_channel.save!

    # TODO fix this message to be the original message
    reply "GeoChat Alerts. You sent '#{@message.strip}' and we have turned off SMS updates to this phone. Reply with START to turn back on. Questions email support@instedd.org."
  end

  def process_on(node)
    return not_logged_in unless current_user

    if current_channel.status != :on
      current_channel.status = :on
      current_channel.save!
    end

    # TODO fix this message to be the original message
    reply "You sent '#{@message.strip}' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  def process_invite(node)
    return not_logged_in unless current_user

    group = node.fix_group || default_group({
      :no_default_group_message => "You must specify a group to invite the users to, or set a default group.",
      :no_groups_message => "You don't belong to any group yet. To join a group send: join groupalias"
    })
    return if not group

    sent = []

    node.users.each do |name|
      user = User.find_by_login name
      user = User.find_by_mobile_number(name) if !user && name.integer?

      if user
        invite = Invite.find_by_group_and_user group, user
        if invite
          if invite.user_accepted
            join user, group
            invite.destroy
          elsif current_user.is_owner_of(group)
            invite.admin_accepted = true
            invite.save!
          else
            # Invite was already sent... should we resend it?
          end
        else
          current_user.invite user, :to => group
          send_message_to_user user, "#{current_user.login} has invited you to group #{group.alias}. You can join by sending: join #{group.alias}"
        end
        sent << name
      else
        if name.integer?
          current_user.invite name, :to => group
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
    return not_logged_in unless current_user

    group = Group.find_by_alias node.group
    if group.requires_aproval_to_join
      invite = Invite.find_by_group_and_user group, current_user
      if invite
        if invite.admin_accepted
          invite.destroy

          join current_user, group
        else
          invite.user_accepted = true
          invite.save!

          notify_join_request group
        end
      else
        current_user.request_join group
        notify_join_request group
      end
    else
      invite = Invite.find_by_group_and_user group, current_user
      invite.destroy if invite

      join current_user, group
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

    group = default_group
    return unless group

    user.make_owner_of group
  end

  def process_message(node)
    if node.target.present?
      if node.target.is_a?(UnknownTarget)
        group = Group.find_by_alias node.target.name
        user = User.find_by_login_or_mobile_number node.target.name unless group
      elsif node.target.is_a?(GroupTarget)
        group = node.target.payload[:group]
        explicit_group = true
        invite = node.target.payload[:invite]
      end

      if node.second_target
        if group
          user = User.find_by_login_or_mobile_number node.second_target.name
        elsif user
          group = Group.find_by_alias node.second_target.name
          explicit_group = true
        end
      end

      if !group && !user
        return reply "The group #{node.target.name} does not exist"
      end
    end

    if group && !group.enabled
      return reply "You can't send messages to #{group.alias} because it is disabled."
    end

    group = default_group unless group
    return unless group

    if user
      if explicit_group && !user.belongs_to(group)
        return reply "You can't send a message to user #{user.login} via group #{group.alias} because he/she does not belong to it"
      elsif !current_user.shares_a_common_group_with(user)
        return reply "You can't send a message to user #{user.login} because you don't share a common group"
      end
    end

    if invite
      if invite.admin_accepted || !group.requires_aproval_to_join
        join current_user, group
        invite.destroy
      else
        return reply "You can not send messages to the group #{group.alias} as your invitation has not yet been approved by an admin."
      end
    end

    if !group.users.include?(current_user)
      if group.requires_aproval_to_join
        return reply "You can not send messages to the group #{group.alias} because you are not a member or the group requires approval to join. To request an invitation send: join #{group.alias}"
      else
        join current_user, group
      end
    end

    if node.location.present?
      coords = Geocoder.locate(node.location)
      reply "Your location was successfully updated to #{node.location} (lat: #{coords.first}, lon: #{coords.second})"
    end

    if node.body.blank?
      if node.location.present?
        node.body = "at #{node.location}"
      end
    end

    if user
      send_message_to_user_in_group user, group, "#{current_user.login} only to you: #{node.body}"
      if group.forward_owners
        send_message_to_group_owners group, "#{current_user.login} only to #{user.login}: #{node.body}", :except => user
      end
    elsif group.chatroom || node.blast
      send_message_to_group group, "#{current_user.login}: #{node.body}"
    elsif group.forward_owners
      send_message_to_group_owners group, "#{current_user.login}: #{node.body}"
    end
  end

  def get_target(name)
    if current_user
      group = current_user.groups.find_by_alias(name)
      if group
        return GroupTarget.new(name, :group => group) if group
      end

      invite = Invite.joins(:group).where('user_id = ? and groups.alias = ?', current_user.id, name).first
      if invite
        return GroupTarget.new(name, :group => invite.group, :invite => invite)
      end
    end

    nil
  end

  private

  def join(user, group)
    user.join group
    if user.memberships.count > 1
      send_message_to_user user, "Welcome #{user.display_name} to #{group.alias}. Send '#{group.alias} Hello group!'"
    else
      send_message_to_user user, "Welcome #{user.display_name} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    end
  end

  def not_logged_in
    reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def reply(msg)
    @messages[@address] << msg
  end

  def notify_join_request(group)
    send_message_to_group_owners group, "An invitation is pending for approval. To approve it send: invite #{group.alias} #{current_user.login}"
    reply "Group #{group.alias} requires approval to join by an Administrator. We will let you know when you can start sending messages."
  end

  def send_message_to_group(group, msg)
    group.users.reject{|x| x.id == current_user.id}.each do |user|
      send_message_to_user_in_group user, group, msg
    end
  end

  def send_message_to_group_owners(group, msg, options = {})
    targets = group.owners
    targets.reject!{|x| x == options[:except]} if options[:except]
    targets.each do |user|
      send_message_to_user_in_group user, group, msg
    end
  end

  def send_message_to_user_in_group(user, group, msg)
    if group.id == user.default_group_id || user.memberships.count == 1
      send_message_to_user user, msg
    else
      send_message_to_user user, "[#{group.alias}] #{msg}"
    end
  end

  def send_message_to_user(user, msg)
    if user == current_user
      reply msg
    else
      user.channels.each do |channel|
        send_message_to_channel channel, msg
      end
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

  def default_group(options = {})
    group = current_user.default_group
    return group if group

    groups = current_user.groups
    if groups.empty?
      reply options[:no_groups_message]
    elsif groups.length == 1
      return groups.first
    else
      reply options[:no_default_group_message]
    end

    nil
  end
end
