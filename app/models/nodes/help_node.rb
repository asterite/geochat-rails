class HelpNode < Node
  command do
    name 'help', 'h', '\?'
    args :node, :optional => true
  end

  def after_scan
    self.node = self.node.command if self.node.is_a? String
  end

  def process
    reply (@node || HelpNode)::Help
  end
end
