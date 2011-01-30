class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :group

  def self.create_from_hash(hash)
    return unless hash

    msg = Message.new
    [:group, :sender, :receiver, :text, :lat, :lon, :location].each do |method|
      msg.send "#{method}=", hash.delete(method)
    end
    msg.save!
  end

  def as_json(options = {})
    hash = {:id => self.id, :text => self.text, :group => self.group.alias, :sender => self.sender.login}
    hash[:lat] = self.lat.to_f if self.lat.present?
    hash[:long] = self.lon.to_f if self.lon.present?
    hash[:location] = self.location if self.location.present?
    hash[:created] = self.created_at
    hash
  end
end
