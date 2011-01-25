# coding: utf-8

require 'unit/pipeline_test'

class LoginTest < PipelineTest
  test "login" do
    send_message "sms://1", ".name User1"
    send_message "sms://1", "#bye"

    send_message "sms://1", "I am User1 MockPassword"
    assert_user_is_logged_in "sms://1", "User1"
    assert_messages_sent_to "sms://1", "Hello User1. When you want to remove this device send: bye"
  end
end
