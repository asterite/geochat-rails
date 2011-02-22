class OffNode < Node
  command

  Command = ::Command.new self do
    name 'off', 'stop'
    name '-', :prefix => :none
  end
end
