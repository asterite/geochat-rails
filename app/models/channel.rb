class Channel < ActiveRecord::Base
  ProtocolNames = {
    'mailto' => 'email',
    'sms' => 'phone',
    'twitter' => 'twitter',
    'xmpp' => 'instant messenger'
  }

  belongs_to :user

  def status
    self.attributes['status'].try(:to_sym)
  end

  def active?
    self.status == :on
  end

  def full_address
    "#{protocol}://#{address}"
  end

  def protocol_name
    Channel::ProtocolNames[self.protocol]
  end

  def turn(status)
    return false if self.status == status

    self.status = status
    self.save!
    true
  end
end
