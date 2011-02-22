class HelpNode < Node
  command
  Help = "GeoChat help center. Send help followed by a topic. Topics: signup, login, logout, create, join, leave, invite, on, off, my, whereis, whois, owner."

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
