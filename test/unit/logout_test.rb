# coding: utf-8

require 'unit/pipeline_test'

class LogoutTest < PipelineTest
  test "logout" do
    send_message "sms://1", ".name John Doe"
    send_message "sms://1", "#bye"

    assert_channel_does_not_exist "sms://1"
    assert_messages_sent_to "sms://1", "John Doe, this device has been removed from your account."
  end

  test "logout twice" do
    send_message "sms://1", "name John Doe"
    send_message "sms://1", "bye"
    send_message "sms://1", "bye"

    assert_channel_does_not_exist "sms://1"
    assert_messages_sent_to "sms://1", 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end
end
