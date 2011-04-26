class CustomChannel < ActiveRecord::Base
  belongs_to :group

  validates :name, :presence => true, :format => {:with => /\A[a-zA-Z0-9]+\Z/, :message => 'can only contain alphanumeric characters'}
  validates_presence_of :group_id

  after_validation :create_nuntium_channel, :on => :create
  before_destroy :delete_nuntium_channel

  private

  def create_nuntium_channel
    response = Nuntium.new_from_config.create_channel({
      :name => name,
      :kind => nuntium_kind,
      :protocol => 'sms',
      :direction => direction,
      :enabled => true,
      :priority => 10,
      :configuration => data,
      :restrictions => [:name => 'group', :value => group.alias],
    })
    p response
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
