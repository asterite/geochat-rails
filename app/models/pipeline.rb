class Pipeline
  include ActionView::Helpers::DateHelper

  attr_accessor :messages
  attr_accessor :saved_messages

  # Processes a message, which is a hash.
  #
  # :from => who send the message (i.e.: sms://1234)
  # :body => the content of the message
  #
  # After processing a message you can see the results by
  # accessing Pipeline#messages, which is a hash whose
  # key is an address and value is the content of the message
  # to be sent as a result of processing the input message.
  def process(message = {})
    message = message.with_indifferent_access

    @address = message[:from]
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @message = message
    @messages = Hash.new{|h, k| h[k] = []}
    @saved_messages = Hash.new{|h, k| h[k] = []}

    node = Parser.parse(message[:body], self, :parse_signup_and_join => !current_user)

    # Remove Node part and put first letter in downcase
    node_name = node.class.name[0 ... -4].underscore
    send "process_#{node_name}", node
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

  def process_signup(node)
    return reply "This device already belongs to another user. To dettach it send: bye" if current_channel

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
    return reply_not_logged_in unless current_channel

    current_channel.destroy

    reply "#{current_channel.user.display_name}, this device has been removed from your account."
  end

  def process_create_group(node)
    return reply_not_logged_in unless current_user

    if Group.find_by_alias(node.alias)
      return reply "The group #{node.alias} already exists. Please specify another alias."
    end

    group = current_user.create_group :alias => node.alias, :name => (node.name || node.alias), :chatroom => !node.nochat

    reply "Group '#{group.alias}' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: #{group.alias} +PHONE_NUMBER"
  end

  def process_off(node)
    return reply_not_logged_in unless current_user
    return if current_channel.status == :off

    current_channel.status = :off
    current_channel.save!

    # TODO fix this message to be the original message
    reply "GeoChat Alerts. You sent '#{@message[:body].strip}' and we have turned off SMS updates to this phone. Reply with START to turn back on. Questions email support@instedd.org."
  end

  def process_on(node)
    return reply_not_logged_in unless current_user

    if current_channel.status != :on
      current_channel.status = :on
      current_channel.save!
    end

    # TODO fix this message to be the original message
    reply "You sent '#{@message[:body].strip}' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  def process_invite(node)
    return reply_not_logged_in unless current_user

    group = node.fix_group || default_group({
      :no_default_group_message => "You must specify a group to invite the users to, or set a default group.",
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
    return reply_not_logged_in unless current_user

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

  def process_leave(node)
    group = Group.find_by_alias node.group
    if !group
      return reply_group_does_not_exist(node.group)
    end

    membership = current_user.membership_in(group)
    if !membership
      return reply "You can't leave group #{group.alias} because you don't belong to it."
    end

    if group.owners == [current_user]
      return reply "You can't leave group #{group.alias} because you are its only owner."
    end

    membership.destroy

    groups = current_user.groups
    case groups.count
    when 0
      reply "Good bye #{current_user.login} from your only group #{group.alias}. To join another group send: join groupalias"
    when 1
      reply "Good bye #{current_user.login} from group #{group.alias}. Now your default group is #{groups.first.alias}."
    else
      reply "Good bye #{current_user.login} from group #{group.alias}."
    end
  end

  def process_my(node)
    case node.key
    when MyNode::Login
      if node.value
        reply "Your can't change your login"
      else
        reply "Your login is: #{current_user.login}"
      end
    when MyNode::Name
      if node.value
        current_user.display_name = node.value
        current_user.save!

        reply "Your new display name is: #{current_user.display_name}"
      else
        reply "Your display name is: #{current_user.display_name}"
      end
    when MyNode::Password
      if node.value
        current_user.password = node.value
        current_user.save!

        reply "Your new password is: #{node.value}"
      else
        reply "Forgot your password? Set it via: #my password newpassword"
      end
    when MyNode::Number
      if node.value
        reply "You can't change your phone number."
      else
        sms_channel = current_user.sms_channel
        if sms_channel
          reply "Your phone number is: #{sms_channel.address}"
        else
          reply "You don't have a phone number configured to work with GeoChat."
        end
      end
    when MyNode::Groups
      groups = current_user.groups.map(&:alias).sort
      case groups.count
      when 0
        return reply_dont_belong_to_any_group
      when 1
        reply "Your only group is: #{groups.first}"
      else
        reply "Your groups are: #{groups.join ', '}"
      end
    when MyNode::Group
      if node.value
        group = Group.find_by_alias node.value
        if !group
          return reply_group_does_not_exist node.value
        end

        if !current_user.belongs_to(group)
          return reply "You can't set #{group.alias} as your default group because you don't belong to it."
        end

        current_user.default_group_id = group.id
        current_user.save!

        return reply "Your new default group is: #{group.alias}"
      end

      group = current_user.default_group || default_group({
        :no_default_group_message => "Your don't have a default group. To choose one send: #my group groupalias"
      })
      return unless group

      reply "Your default group is: #{group.alias}"
    when MyNode::Location
      if node.value
        update_current_user_location_to node.value
        return
      end

      if !current_user.location_known?
        return reply "You never reported your location."
      end

      return reply "You said you was in #{current_user.location} (lat: #{current_user.lat}, lon: #{current_user.lon}) #{time_ago_in_words current_user.location_reported_at} ago."
    end
  end

  def process_owner(node)
    user = User.find_by_login_or_mobile_number node.user
    if node.group
      group = Group.find_by_alias node.group
      if !group
        node.user, node.group = node.group, node.user
        group = Group.find_by_alias node.group
        user = User.find_by_login_or_mobile_number node.user
        if !group
          if user
            return reply_group_does_not_exist node.group
          else
            return reply_group_does_not_exist("#{node.group} or #{node.user}")
          end
        end
      end
    end

    if !user
      return reply_user_does_not_exist node.user
    end

    if not group
      group = default_group({
        :no_default_group_message => "You must specify a group to set #{user.login} as an owner, or set a default group.",
      })
    end
    return unless group

    if !user.belongs_to(group)
      return reply "The user #{user.login} does not belong to group #{group.alias}."
    end

    user.make_owner_of group

    reply "The user #{user.login} was successfully set as owner of group #{group.alias}."
    send_message_to_user user, "#{current_user.login} has made you owner of group #{group.alias}."
  end

  def process_message(node)
    if !current_user
      return reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
    end

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
        return reply_group_does_not_exist node.target.name
      end
    end

    # This is needed here and also bellow. Here because if there is an explicit
    # target group we don't want to allow sending even location updates.
    # Below because if an explicit group is not found then it is the default group
    # and it might be disabled.
    if group && !group.enabled
      return reply "You can't send messages to #{group.alias} because it is disabled."
    end

    if node.location.present?
      place, coords = update_current_user_location_to node.location

      if node.body.blank?
        node.body = "at #{place} (lat: #{coords.first}, lon: #{coords.second})"
      else
        node.body = "#{node.body} (at #{place}, lat: #{coords.first}, lon: #{coords.second})"
      end
    end

    if not group
      group = default_group({
        :no_default_group_message => "You don't have a default group so prefix messages with a group (for example: groupalias Hello!) or set your default group with: #my group groupalias"
      })
    end
    return unless group

    if group && !group.enabled
      return reply "You can't send messages to #{group.alias} because it is disabled."
    end

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

  def process_where_is(node)
    user = User.find_by_login_or_mobile_number node.user
    if !user
      return reply_user_does_not_exist node.user
    end

    if !current_user.shares_a_common_group_with(user)
      return reply "You can't see the location of #{user.login} because you don't share a common group."
    end

    if !user.location_known?
      return reply "#{user.login} never reported his/her location."
    end

    reply "User2 said he/she was in #{user.location} (lat: #{user.lat}, lon: #{user.lon}) #{time_ago_in_words user.location_reported_at} ago."
  end

  def join(user, group)
    user.join group
    if user.memberships.count > 1
      send_message_to_user user, "Welcome #{user.display_name} to #{group.alias}. Send '#{group.alias} Hello group!'"
    else
      send_message_to_user user, "Welcome #{user.display_name} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    end
  end

  def reply_not_logged_in
    reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def reply_user_does_not_exist(user)
    reply "The user #{user} does not exist."
  end

  def reply_group_does_not_exist(group)
    reply "The group #{group} does not exist."
  end

  def reply_dont_belong_to_any_group
    reply "You don't belong to any group yet. To join a group send: join groupalias"
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

  def update_current_user_location_to(location)
    if location.is_a?(String)
      place, coords = location, Geocoder.locate(location)
    else
      place, coords = Geocoder.reverse(location), location
    end

    current_user.location = place
    current_user.coords = coords
    current_user.save!

    reply "Your location was successfully updated to #{place} (lat: #{coords.first}, lon: #{coords.second})"

    [place, coords]
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
      reply_dont_belong_to_any_group
    elsif groups.length == 1
      return groups.first
    else
      reply options[:no_default_group_message]
    end

    nil
  end
end
