class Node
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
