class XmppChannel < Channel
  before_save :set_activation_code, :if => :activation_pending?

  def protocol_name
    "instant messenger"
  end

  private

  def set_activation_code
    self.activation_code = PasswordGenerator.new_password
  end
end
