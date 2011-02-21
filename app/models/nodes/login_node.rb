class LoginNode < Node
  attr_accessor :login
  attr_accessor :password

  Command = ::Command.new self do
    name 'login', 'log in', 'li', 'iam', 'i am', "i'm", 'im'
    name '\(', :space_after_command => false
    name 'li', :prefix => :required
    args :login, :password, :spaces_in_args => false
  end
end
