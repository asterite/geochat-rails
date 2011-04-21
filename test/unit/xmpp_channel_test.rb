require 'test_helper'

class XmppChannelTest < ActiveSupport::TestCase
  test "set activation code when creating a pending channel" do
    PasswordGenerator.expects(:new_password).returns('abcd')

    user = User.make
    channel = user.xmpp_channels.make :status => :pending, :address => 'foo@bar.com'

    assert_equal 'abcd', channel.activation_code
  end

  test "activate channel via xmpp" do
    PasswordGenerator.expects(:new_password).returns('abcd')

    user = User.make
    channel = user.xmpp_channels.make :status => :pending, :address => 'foo@bar.com'

    messages = Node.process :from => 'xmpp://foo@bar.com', :body => 'abcd'
    assert_equal [:from => 'geochat://system', :to => 'xmpp://foo@bar.com', :body => T.you_can_now_send_and_receive_messages_via_this_channel(user.login)], messages

    channel.reload

    assert channel.on?
    assert_nil channel.activation_code
  end

  test "activate channel via xmpp fails" do
    PasswordGenerator.expects(:new_password).returns('abcd')

    user = User.make
    channel = user.xmpp_channels.make :status => :pending, :address => 'foo@bar.com'

    messages = Node.process :from => 'xmpp://foo@bar.com', :body => 'xyz'
    assert_equal [:from => 'geochat://system', :to => 'xmpp://foo@bar.com', :body => T.incorrect_activation_code('xyz')], messages

    channel.reload

    assert channel.activation_pending?
  end
end

