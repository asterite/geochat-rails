class StringScanner
  def command(node, &block)
    command = Command.new node
    command.instance_eval(&block)
    command.scan self
  end
end
