class Pipeline
  attr_accessor :messages

  def process(address, message)
    @messages = Hash.new{|k, v| k[v] = []}

    node = Parser.parse(message)
    case node
    when SignupNode
      process_signup node, address, message
    when LoginNode
      process_login node, address, message
    when LogoutNode
      process_logout node, address, message
    end
  end

  def process_signup(node, address, message)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    if channel
      @messages[address] << "This device already belongs to other user. To dettach it send: bye"
      return
    end

    password = PasswordGenerator.new_password

    login = node.suggested_login
    index = 2
    while User.find_by_login(login)
      login = "#{node.suggested_login}#{index}"
      index += 1
    end

    user = User.create! :login => login, :display_name => node.display_name
    channel = Channel.create! :protocol => protocol, :address => address2, :user => user
    @messages[address] << "Welcome #{user.display_name} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    @messages[address] << "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"
    @messages[address] << "To send messages to a group, you must first join one. Send: join GROUP"
  end

  def process_login(node, address, message)
  end

  def process_logout(node, address, message)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    user = channel.user

    channel.destroy

    @messages[address] << "#{user.display_name}, this device has been removed from your account."
  end
end
