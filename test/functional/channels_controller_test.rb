require 'test_helper'

class ChannelsControllerTest < ActionController::TestCase
  setup do
    @user = login User.make
  end

  test "create email" do
    post :create_email, :channel => {:email => 'foo@bar.com'}

    channels = Channel.all
    assert_equal 1, channels.length

    channel = Channel.first
    assert_equal 'mailto', channel.protocol
    assert_equal @user, channel.user
    assert_equal :pending, channel.status
    assert_not_nil channel.confirmation_code

    assert_equal 'An email has been sent to foo@bar.com', flash[:notice]
    assert_redirected_to channels_path
  end

  test "activate email" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending, :confirmation_code => '1234'

    get :activate_email, :id => channel.id, :code => channel.confirmation_code

    channel.reload
    assert_equal :on, channel.status
    assert_nil channel.confirmation_code

    assert_equal "Your email channel for foo@bar.com is now active", flash[:notice]
    assert_redirected_to channels_path
  end

  test "activate email with wrong code" do
    channel = @user.email_channels.create! :address => 'foo@bar.com', :status => :pending, :confirmation_code => '1234'

    get :activate_email, :id => channel.id, :code => '5678'

    channel.reload
    assert_equal :pending, channel.status

    assert_equal "The confirmation code for activating the email is wrong", flash[:notice]
    assert_redirected_to channels_path
  end
end
