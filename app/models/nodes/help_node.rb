class HelpNode < Node
  command
  Help = T.help_general

  attr_accessor :node

  Command = ::Command.new self do
    name 'help', 'h', '\?'
    args :node, :optional => true
  end

  def after_scan
    self.node = self.node.command if self.node.is_a? String
  end

  def process
    node = @node || HelpNode
    reply node::Help
  end
end
