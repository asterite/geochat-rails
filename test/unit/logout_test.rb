# coding: utf-8

require 'unit/pipeline_test'

class LogoutTest < PipelineTest
  test "logout" do
    send_message 1, ".name John Doe"
    send_message 1, "bye"

    assert_channel_does_not_exist "sms://1"
    assert_messages_sent_to 1, "John Doe, this device has been removed from your account."
  end

  test "logout twice" do
    send_message 1, "name John Doe"
    send_message 1, "bye"
    send_message 1, "bye"

    assert_channel_does_not_exist "sms://1"
    assert_not_logged_in_message_sent_to "sms://1"
  end
end
