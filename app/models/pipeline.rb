class Pipeline
  attr_accessor :messages

  def process(address, message)
    @address = address
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @message = message
    @messages = Hash.new{|k, v| k[v] = []}

    node = Parser.parse(message)
    case node
    when SignupNode
      process_signup node
    when LoginNode
      process_login node
    when LogoutNode
      process_logout node
    end
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
    channel = Channel.create! :protocol => @protocol, :address => @address2, :user => user
    reply "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    reply "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"
    reply "To send messages to a group, you must first join one. Send: join GROUP"
  end

  def process_login(node)
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

  def current_channel
    @channel ||= Channel.find_by_protocol_and_address @protocol, @address2
  end
end