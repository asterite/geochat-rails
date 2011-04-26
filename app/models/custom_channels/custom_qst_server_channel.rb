class CustomQstServerChannel < CustomChannel
  data_accessor :password
  validates_confirmation_of :password

  def kind
    "sms"
  end

  def nuntium_kind
    'qst_server'
  end
end
