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
  attr_accessor :pipeline

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

  def current_channel
    @pipeline.current_channel
  end

  def current_user
    @pipeline.current_user
  end

  def channel=(chan)
    @pipeline.channel = chan
  end

  def message
    @pipeline.message
  end

  def saved_message=(msg)
    @pipeline.saved_message = msg
  end

  def reply(msg)
    @pipeline.reply(msg)
  end

  def address2
    @pipeline.address2
  end

  def create_channel_for(user)
    @pipeline.create_channel_for user
  end

  def method_missing(name, *args)
    if @pipeline && @pipeline.respond_to?(name)
      @pipeline.send name, *args
    else
      super
    end
  end
end

# Load all nodes
Dir["#{Rails.root}/app/models/nodes/*"].each do |file|
  eval(ActiveSupport::Inflector.camelize(file[file.rindex('/') + 1 .. -4]))
end
