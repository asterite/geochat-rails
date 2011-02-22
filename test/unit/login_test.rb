# coding: utf-8

require 'unit/pipeline_test'

class LoginTest < PipelineTest
  test "login" do
    send_message 1, ".name User1"
    send_message 1, "bye"

    send_message 1, "I am User1 MockPassword"
    assert_user_is_logged_in "sms://1", "User1"
    assert_messages_sent_to 1, T.hello('User1')
  end

  test "login wrong username" do
    send_message 1, ".name User1"
    send_message 1, "bye"

    send_message 1, "I am User2 MockPassword"
    assert_channel_does_not_exist "sms://1"
    assert_messages_sent_to "sms://1", T.invalid_login
  end

  test "login wrong password" do
    send_message 1, ".name User1"
    send_message 1, "bye"

    send_message 1, "I am User1 WrongPassword"
    assert_channel_does_not_exist "sms://1"
    assert_messages_sent_to 1, T.invalid_login
  end

  test "login when already logged in with another user" do
    send_message 1, ".name User1"
    send_message 1, "bye"
    send_message 1, ".name User2"
    send_message 1, "I am User2 MockPassword"

    send_message 1, "I am User1 MockPassword"
    assert_user_is_logged_in "sms://1", "User1"
    assert_messages_sent_to 1, T.hello('User1')
  end

end
