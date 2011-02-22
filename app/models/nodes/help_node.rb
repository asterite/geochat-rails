class HelpNode < Node
  command

  attr_accessor :node

  Command = ::Command.new self do
    name 'help', 'h', '\?'
    args :node, :optional => true
  end

  def after_scan
    self.node = self.node.command if self.node.is_a? String
  end
end
