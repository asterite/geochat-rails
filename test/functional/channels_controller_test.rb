require 'test_helper'

class ChannelsControllerTest < ActionController::TestCase
  setup do
    @user = login User.make
  end

  test "create email" do
    post :create_email, :email_channel => {:address => 'foo@bar.com'}

    channels = Channel.all
    assert_equal 1, channels.length

    channel = Channel.first
    assert_equal 'mailto', channel.protocol
    assert_equal @user, channel.user
    assert_equal :pending, channel.status
    assert_not_nil channel.activation_code

    assert_equal 'An email has been sent to foo@bar.com', flash[:notice]
    assert_redirected_to channel_path(channel)
  end

  test "can't create email if already exists one" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending, :activation_code => '1234'

    post :create_email, :email_channel => {:address => 'foo@bar.com'}

    assert_equal 1, Channel.count

    assert_template 'new_email'
  end

  test "create mobile phone" do
    SmsChannel.any_instance.expects(:prepend_country_prefix_to_address)
    SmsChannel.any_instance.expects(:send_activation_code)

    post :create_mobile_phone, :sms_channel => {:address => '1234', :country => 'ar', :carrier => 'foo'}

    channels = Channel.all
    assert_equal 1, channels.length

    channel = Channel.first

    assert_equal 'sms', channel.protocol
    assert_equal @user, channel.user
    assert_equal :pending, channel.status
    assert_equal 'ar', channel.country
    assert_equal 'foo', channel.carrier
    assert_not_nil channel.activation_code

    assert_equal 'A message has been sent to 1234', flash[:notice]
    assert_redirected_to channel_path(channel)
  end

  test "create xmpp" do
    post :create_xmpp, :xmpp_channel => {:address => 'foo@bar.com'}

    channels = Channel.all
    assert_equal 1, channels.length

    channel = Channel.first

    assert_equal 'xmpp', channel.protocol
    assert_equal @user, channel.user
    assert_equal :pending, channel.status
    assert_not_nil channel.activation_code

    assert_redirected_to channel_path(channel)
  end

  test "activate" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending, :activation_code => '1234'

    get :activate, :id => channel.id, :activation_code => channel.activation_code

    channel.reload
    assert_equal :on, channel.status
    assert_nil channel.activation_code

    assert_equal "Your email channel for foo@bar.com is now active", flash[:notice]
    assert_redirected_to channels_path
  end

  test "activate with wrong code" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending, :activation_code => '1234'

    get :activate, :id => channel.id, :activation_code => '5678'

    channel.reload
    assert_equal :pending, channel.status

    assert_template 'show'
  end

  test "destroy channel" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :on

    get :destroy, :id => channel.id

    assert_equal 0, Channel.count
    assert_equal "Channel foo@bar.com deleted", flash[:notice]
    assert_redirected_to channels_path
  end

  test "turn channel on" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :off

    get :turn_on, :id => channel.id

    channel.reload

    assert_equal :on, channel.status
    assert_equal "Channel foo@bar.com turned on", flash[:notice]
    assert_redirected_to channels_path
  end

  test "turn channel off" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :on

    get :turn_off, :id => channel.id

    channel.reload

    assert_equal :off, channel.status
    assert_equal "Channel foo@bar.com turned off", flash[:notice]
    assert_redirected_to channels_path
  end

  [:on, :off].each do |status|
    test "cant turn #{status} if pending" do
      channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending

      get "turn_#{status}", :id => channel.id

      channel.reload

      assert_equal :pending, channel.status
      assert_redirected_to channels_path
    end
  end
end
