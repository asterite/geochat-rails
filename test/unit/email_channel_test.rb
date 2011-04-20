require 'test_helper'

class EmailChannelTest < ActiveSupport::TestCase
  test "send confirmation email when creating a pending channel" do
    user = User.make
    channel = user.email_channels.make :status => :pending

    assert_not_nil channel.confirmation_code
    assert_equal 1, ActionMailer::Base.deliveries.length
    assert_equal "Activation of your email channel", ActionMailer::Base.deliveries.first.subject
    p ActionMailer::Base.deliveries.first.encoded
  end
end
