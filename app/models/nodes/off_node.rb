class OffNode < Node
  Command = ::Command.new self do
    name 'off', 'stop'
    name '-', :prefix => :none
  end
end
