class OnNode < Node
  command

  Command = ::Command.new self do
    name 'on', 'start'
    name '\!', :prefix => :none
  end
end
