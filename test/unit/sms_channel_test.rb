require 'test_helper'

class SmsChannelTest < ActiveSupport::TestCase
  test "send activation code and prepend country phone prefix when creating a pending channel" do
    PasswordGenerator.expects(:new_password).returns('abcd')

    nuntium = mock('nuntium')
    Nuntium.expects(:new_from_config).times(2).returns(nuntium)
    nuntium.expects(:country).with('ar').returns({'name' => 'Argentina', 'phone_prefix' => '54'})
    nuntium.expects(:send_ao).with(
      :from => 'geochat://system',
      :to => 'sms://541234',
      :body => "Enter the following code in the website to activate this phone: abcd",
      :country => 'ar',
      :carrier => 'foo'
    )

    user = User.make
    channel = user.sms_channels.make_unsaved :status => :pending, :address => '1234'
    channel.country_iso2 = 'ar'
    channel.carrier_guid = 'foo'
    channel.save!

    assert_equal 'abcd', channel.activation_code
    assert_equal '541234', channel.address
    assert_equal '1234', channel.mobile_number
    assert_equal 'Argentina', channel.country_name
    assert_equal '54', channel.country_prefix_number
  end
end
