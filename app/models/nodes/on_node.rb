class OnNode < Node
  Command = ::Command.new self do
    name 'on', 'start'
    name '\!', :prefix => :none
  end
end
