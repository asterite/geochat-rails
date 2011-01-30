class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :group

  def to_json(options = {})
    hash = {:id => self.id, :text => self.text, :group => self.group.alias, :sender => self.sender.login}
    hash[:lat] = self.lat.to_f if self.lat.present?
    hash[:long] = self.lon.to_f if self.lon.present?
    hash[:location] = self.location if self.location.present?
    hash[:created] = self.created_at
    hash.to_json
  end
end
