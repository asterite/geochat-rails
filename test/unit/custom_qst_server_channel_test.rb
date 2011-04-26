require 'test_helper'

class CustomQstServerChannelTest < ActiveSupport::TestCase
  test "create nuntium channel on create and delete on destroy" do
    group = Group.make

    nuntium = mock('nuntium')
    Nuntium.expects(:new_from_config).returns(nuntium)
    nuntium.expects(:create_channel).with({
      :name => 'foo',
      :kind => 'qst_server',
      :protocol => 'sms',
      :direction =>'incoming',
      :enabled => true,
      :priority => 10,
      :configuration => {:password => 'bar'},
      :restrictions => [:name => 'group', :value => group.alias],
    }).returns(stub(:code => 200))

    channel = group.custom_qst_server_channels.create! :name => 'foo', :password => 'bar', :password_confirmation => 'bar', :direction => 'incoming'

    nuntium = mock('nuntium')
    Nuntium.expects(:new_from_config).returns(nuntium)
    nuntium.expects(:delete_channel).with('foo').returns(stub(:code => 200))

    channel.destroy
  end
end
