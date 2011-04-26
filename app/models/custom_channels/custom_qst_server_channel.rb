class CustomQstServerChannel < CustomChannel
  data_accessor :password
  validates_confirmation_of :password

  after_validation :create_nuntium_channel, :on => :create
  before_destroy :delete_nuntium_channel

  def kind
    "sms"
  end

  private

  def create_nuntium_channel
    response = Nuntium.new_from_config.create_channel({
      :name => name,
      :kind => 'qst_server',
      :protocol => 'sms',
      :direction => direction,
      :enabled => true,
      :priority => 10,
      :configuration => {:password => password},
      :restrictions => [:name => 'group', :value => group.alias],
    })
    if response.code != 200
      response['properties'].each do |props|
        props.each do |key, value|
          errors.add(key.to_sym, value)
        end
      end
    end
  end

  def delete_nuntium_channel
    response = Nuntium.new_from_config.delete_channel name
    if response.code != 200
      raise "Couldn't delete nuntium channel"
    end
  end
end
