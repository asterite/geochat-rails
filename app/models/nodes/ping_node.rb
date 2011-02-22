class PingNode < Node
  command

  attr_accessor :text

  Command = ::Command.new self do
    name 'ping'
    args :text, :optional => true
    help :no
  end
end
