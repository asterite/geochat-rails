class Pipeline
  attr_accessor :messages

  def process(address, message)
    @address = address
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @message = message
    @messages = Hash.new{|k, v| k[v] = []}

    node = Parser.parse(message)

    # Remove Node part and put first letter in downcase
    node_name = node.class.name[0].downcase + node.class.name[1 ... -4].downcase
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

    user = User.create! :login => login, :display_name => node.display_name
    channel = create_channel_for user
    reply "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    reply "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"
    reply "To send messages to a group, you must first join one. Send: join GROUP"
  end

  def process_login(node)
    user = User.find_by_login node.login
    channel = create_channel_for user
    reply "Hello #{user.display_name}. When you want to remove this device send: bye"
  end

  def process_logout(node)
    return not_logged_in unless current_channel

    user = current_channel.user

    current_channel.destroy

    reply "#{user.display_name}, this device has been removed from your account."
  end

  def not_logged_in
    reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def reply(msg)
    @messages[@address] << msg
  end

  def create_channel_for(user)
    Channel.create! :protocol => @protocol, :address => @address2, :user => user
  end

  def current_channel
    @channel ||= Channel.find_by_protocol_and_address @protocol, @address2
  end
end
