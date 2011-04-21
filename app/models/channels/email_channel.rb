class EmailChannel < Channel
  before_save :set_activation_code, :if => :activation_pending?
  after_save :send_activation_code, :if => :activation_pending?

  def protocol_name
    "email"
  end

  def send_activation_code
    ChannelMailer.activation_email(self).deliver
  end

  private

  def set_activation_code
    self.activation_code = Guid.new.to_s
  end
end
