class LogoutNode < Node
  command

  Command = ::Command.new self do
    name 'logout', 'log out', 'logoff', 'log off', 'bye'
    name 'lo', :prefix => :required
    name '\)', :prefix => :none
  end
end
