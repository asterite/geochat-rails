class LoginNode < Node
  command
  Help = "To login to GeoChat from this channel send: login YOUR_LOGIN YOUR_PASSWORD"

  attr_accessor :login
  attr_accessor :password

  Command = ::Command.new self do
    name 'login', 'log in', 'li', 'iam', 'i am', "i'm", 'im'
    name '\(', :space_after_command => false
    name 'li', :prefix => :required
    args :login, :password, :spaces_in_args => false
  end

  def process
    user = User.authenticate @login, @password
    return reply "Invalid login" unless user

    if current_channel
      current_channel.user = user
      current_channel.save!
    else
      channel = create_channel_for user
    end

    reply "Hello #{user.display_name}. When you want to remove this device send: bye"
  end
end
