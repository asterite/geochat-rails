class UnknownNode < Node
  attr_accessor :command
  attr_accessor :suggestion

  def self.scan(strscan)
    if strscan.scan /^\.+\s*(\S+)\s*(?:.+?)?$/i
      command = strscan[1]
      return UnknownNode.new :command => command
    end
  end
end
