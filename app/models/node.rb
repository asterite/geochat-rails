class Node
  Commands = []
  CommandsWithoutGroup = []

  def self.command
    if Commands.last.try(:name) == 'UnknownNode'
      Commands.insert(Commands.length - 1, self)
    else
      Commands << self
    end
  end

  def self.command_without_group
    CommandsWithoutGroup << self
  end

  def self.names
    self::Command.names
  end


  attr_accessor :matched_name

  def initialize(attrs = {})
    attrs.each do |k, v|
      send "#{k}=", v
    end
  end

  def self.scan(strscan)
    self::Command.scan(strscan)
  end

  def after_scan
  end

  def after_scan_with_group
    after_scan
  end
end

# Load all nodes
Dir["#{Rails.root}/app/models/nodes/*"].each do |file|
  eval(ActiveSupport::Inflector.camelize(file[file.rindex('/') + 1 .. -4]))
end
