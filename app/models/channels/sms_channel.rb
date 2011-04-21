class SmsChannel < Channel
  before_save :set_activation_code, :if => :activation_pending?
  after_save :send_activation_code, :if => :activation_pending?

  data_accessor :country
  data_accessor :carrier

  def protocol_name
    "phone"
  end

  def send_activation_code
    nuntium = Nuntium.new_from_config
    country = nuntium.country self.country

    nuntium.send_ao(
      :from => 'geochat://system',
      :to => "sms://#{country['phone_prefix']}#{address}",
      :body => "Enter the following code in the website to activate this phone: #{activation_code}",
      :country => self.country,
      :carrier => self.carrier
    )
  end

  private

  def set_activation_code
    self.activation_code = PasswordGenerator.new_password
  end
end
