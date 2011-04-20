class EmailChannel < Channel
  before_save :set_confirmation_code, :if => :activation_pending?
  after_save :send_activation_email, :if => :activation_pending?

  def protocol_name
    "email"
  end

  private

  def set_confirmation_code
    self.confirmation_code = Guid.new.to_s
  end

  def send_activation_email
    ChannelMailer.activation_email(self).deliver
  end
end
