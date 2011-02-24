class Node
  Commands = []
  CommandsAfterGroup = []

  def self.command(&block)
    # Insert into Commands array
    if Commands.last.try(:name) == 'UnknownNode'
      Commands.insert(Commands.length - 1, self)
    else
      Commands << self
    end

    if block_given?
      if block.arity == 0
        # Delcare Command constant
        self.const_set :Command, ::Command.new(self, &block)

        # Declare attr_accessors for the parameters
        self::Command.args.each do |args|
          args[:args].each do |arg|
            attr_accessor arg
          end
        end
      else
        metaclass = class << self; self; end
        metaclass.send :define_method, :scan, &block
      end
    end

    # Declare the Help constant
    self.const_set :Help, T.send("help_#{name.underscore[0 .. -6]}") unless self.name == 'UnknownNode'
  end

  def self.command_after_group(&block)
    CommandsAfterGroup << self
    command(&block)

    attr_accessor :group
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
    if @pipeline.respond_to?(name)
      @pipeline.send name, *args
    else
      super
    end
  end
end
