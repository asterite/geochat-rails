class CustomXmppChannel < CustomChannel
  data_accessor :user
  data_accessor :domain
  data_accessor :password
  data_accessor :server
  data_accessor :port, :default => 5222
  data_accessor :resource
  data_accessor :status

  def kind
    'xmpp'
  end

  def nuntium_kind
    'xmpp'
  end
end
