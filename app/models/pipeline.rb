class Pipeline
  attr_accessor :messages

  def process(address, message)
    @address = address
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @message = message
    @messages = Hash.new{|k, v| k[v] = []}

    node = Parser.parse(message, self)

    # Remove Node part and put first letter in downcase
    node_name = node.class.name[0 ... -4].tableize.singularize
    eval("process_#{node_name} node")
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

    user = User.create! :login => login, :password => password, :display_name => node.display_name
    channel = create_channel_for user
    reply "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    reply "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"
    reply "To send messages to a group, you must first join one. Send: join GROUP"
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
    GroupUser.create! :user => current_user, :group => group

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
          group = current_user.groups.first
        end
      end
    else
      group = current_user.groups.first
    end

    sent = []

    node.users.each do |name|
      user = User.find_by_login name
      if user
        Invite.create! :group => group, :user => user
        send_message_to_user user, "#{current_user.login} has invited you to group #{group.alias}. You can join by sending: join #{group.alias}"
        sent << name
      else
        reply "Could not find a registered user '#{name}' for your invitation."
      end
    end

    reply "Invitation/s sent to #{sent.join(', ')}" if sent.present?
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

  def send_message_to_user(user, msg)
    user.channels.each do |channel|
      send_message_to_channel channel, msg
    end
  end

  def send_message_to_channel(channel, msg)
    @messages[channel.full_address] << msg
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
