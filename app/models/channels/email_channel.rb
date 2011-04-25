class EmailChannel < Channel
  validates_uniqueness_of :address, :scope => :protocol
  validates :address, :email_format => {:message => 'is not a valid email address'}

  before_save :set_activation_code, :if => :activation_pending?
  after_save :send_activation_code, :if => :activation_pending?

  def protocol_name
    "email"
  end

  def send_activation_code
    ChannelMailer.activation_email(self).deliver
  end

  def target_address
    Addresses['email']
  end

  private

  def set_activation_code
    self.activation_code = Guid.new.to_s
  end
end
