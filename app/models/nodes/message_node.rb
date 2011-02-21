class MessageNode < Node
  attr_accessor :body
  attr_accessor :targets
  attr_accessor :locations
  attr_accessor :mentions
  attr_accessor :tags
  attr_accessor :blast

  def initialize(attributes = {})
    super

    return unless self.body

    check_mentions
    check_tags
    check_locations
  end

  def location
    @locations.try(:first)
  end

  def location=(value)
    @locations = [value]
  end

  def target
    @targets.try(:first)
  end

  def target=(value)
    @targets = [value]
  end

  def second_target
    @targets.try(:second)
  end

  def check_mentions
    self.body.scan /\s+@\s*(\S+)/ do |match|
      self.mentions ||= []
      self.mentions << match.first
    end
  end

  def check_tags
    self.body.scan /#\s*(\S+)/ do |match|
      self.tags ||= []
      self.tags << match.first
    end
  end

  def check_locations
    self.body.scan /\s+\/[^\/]+\/|\s+\/\S+/ do |match|
      match = match.strip
      match = match[1 .. -1] if match.start_with?('/')
      ['/', ',', '.', ';'].each do |char|
        match = match[0 .. -2] if match.end_with?(char)
      end
      if match.present?
        self.locations ||= []
        self.locations << match.to_location
      end
    end
  end
end
