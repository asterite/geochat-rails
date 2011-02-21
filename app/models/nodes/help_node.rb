class HelpNode < Node
  attr_accessor :node

  Command = ::Command.new self do
    name 'help', 'h', '\?'
    args :node, :optional => true
  end

  def after_scan
    if self.node.is_a? String
      self.node = self.node[1 .. -1] if self.node.start_with?('.')
      self.node = case self.node.downcase
                  when 'my'
                    MyNode
                  end
    end
  end
end
