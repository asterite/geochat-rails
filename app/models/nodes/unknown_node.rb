class UnknownNode < Node
  KnownCommands = ['ping', 'name', 'login', 'iam', 'logout', 'logoff', 'bye', 'on', 'start', 'off', 'stop', 'create', 'creategroup', 'cg', 'invite', 'join', 'leave', 'owner', 'admin', 'my groups', 'my group', 'my name', 'my email', 'my number', 'my phone', 'my phonenumber', 'my mobile', 'my mobilenumber', 'my location', 'my login', 'my password', 'whois', 'whereis', 'lang', 'at', 'help']

  attr_accessor :command

  command do |strscan|
    if strscan.scan /^\.+\s*(\S+)\s*(?:.+?)?$/i
      command = strscan[1]
      return UnknownNode.new :command => command
    end
  end

  def self.names
    []
  end

  def process
    candidate = KnownCommands.min_by {|x| x.levenshtein @command}
    reply T.unknown_command(@command, candidate)
  end
end
