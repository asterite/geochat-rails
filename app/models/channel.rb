class Channel < ActiveRecord::Base
  Protocols = %w(mailto sms twitter xmpp)

  belongs_to :user
  validates_presence_of :protocol, :address, :user, :status

  attr_reader_as_symbol :status

  def active?
    self.status == :on
  end

  def activation_pending?
    self.status == :pending
  end

  def full_address
    "#{protocol}://#{address}"
  end

  def protocol_name
    protocol
  end

  def turn(status)
    return false if self.status == status

    self.status = status
    self.confirmation_code = nil if status == :on
    self.save!
    true
  end

  # ----------------------------------------------------------
  # Make the protocol column work for Single Table Inheritance
  # ----------------------------------------------------------

  set_inheritance_column :protocol

  # We want the SmsChannel class given the "sms" protocol
  def self.find_sti_class(type_name)
    type_name.to_channel
  end

  # We want the single table inheritance name (the protocol column) to be "sms", not "SmsChannel"
  def self.sti_name
    value = super.tableize[0 .. -10]
    value = 'mailto' if value == 'email'
    value
  end
end
