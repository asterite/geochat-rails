class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :group

  before_save :cache_data

  data_accessor :group_alias
  data_accessor :sender_login

  def self.create_from_hash(hash)
    return unless hash

    msg = Message.new
    [:group, :sender, :text, :lat, :lon, :location, :location_short_url].each do |method|
      msg.send "#{method}=", hash.delete(method)
    end
    msg.data = hash
    msg.save!

    msg
  end

  def as_json(options = {})
    hash = {:id => self.id.to_s, :text => self.text, :group => self.group.alias, :sender => self.sender.login}
    hash[:lat] = self.lat.to_f if self.lat.present?
    hash[:long] = self.lon.to_f if self.lon.present?
    hash[:location] = self.location if self.location.present?
    hash[:location_short_url] = self.location_short_url if self.location_short_url.present?
    hash[:created] = self.created_at
    hash
  end

  private

  def cache_data
    self.group_alias = self.group.alias if self.group_id?
    self.sender_login = self.sender.login if self.sender_id?
  end
end
