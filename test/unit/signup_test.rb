# coding: utf-8

require 'unit/pipeline_test'

class SignupTest < PipelineTest
  test "signup" do
    assert_user_doesnt_exist "JohnDoe"

    send_message "sms://1", ".name John Doe"

    assert_user_exists "JohnDoe"
    assert_user_is_logged_in "sms://1", "JohnDoe", "John Doe"
    assert_messages_sent_to "sms://1", [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]
  end

  test "signup already logged in" do
    send_message "sms://1", ".name John Doe"

    send_message "sms://1", ".name John Doe"
    assert_messages_sent_to "sms://1", [
      "This device already belongs to other user. To dettach it send: bye"
    ]
  end

  test "signup with existing display name" do
    send_message "sms://1", ".name John Doe"

    send_message "sms://2", ".name John Doe"

    assert_user_exists "JohnDoe2"
    assert_user_is_logged_in "sms://2", "JohnDoe2", "John Doe"
    assert_messages_sent_to "sms://2", [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe2) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]

    send_message "sms://4", ".name John Doe"

    assert_user_exists "JohnDoe3"
    assert_user_is_logged_in "sms://4", "JohnDoe3", "John Doe"
    assert_messages_sent_to "sms://4", [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe3) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]
  end

  test "signup with fixed country and carrier" do
    # TODO
  end

end
