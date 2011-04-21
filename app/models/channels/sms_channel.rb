class SmsChannel < Channel
  before_save :set_activation_code, :if => :activation_pending?
  before_save :prepend_country_prefix_to_address, :if => proc{|c| c.new_record? && c.activation_pending?}
  after_save :send_activation_code, :if => :activation_pending?

  data_accessor :country
  data_accessor :carrier
  data_accessor :mobile_number

  def protocol_name
    "phone"
  end

  def send_activation_code
    Nuntium.new_from_config.send_ao(
      :from => 'geochat://system',
      :to => "sms://#{address}",
      :body => "Enter the following code in the website to activate this phone: #{activation_code}",
      :country => self.country,
      :carrier => self.carrier
    )
  end

  private

  def prepend_country_prefix_to_address
    self.mobile_number = self.address

    nuntium = Nuntium.new_from_config
    country = nuntium.country self.country
    self.address = "#{country['phone_prefix']}#{self.address}"
  end

  def set_activation_code
    self.activation_code = PasswordGenerator.new_password
  end
end
