# coding: utf-8

require 'unit/pipeline_test'

class SignupTest < PipelineTest
  test "signup" do
    assert_user_doesnt_exist "JohnDoe"

    send_message 1, ".name John Doe"

    assert_user_exists "JohnDoe"
    assert_user_is_logged_in "sms://1", "JohnDoe", "John Doe"
    assert_messages_sent_to "sms://1", [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]
  end

  test "signup already logged in" do
    send_message 1, ".name John Doe"

    send_message 1, ".name John Doe"
    assert_messages_sent_to "sms://1", "This device already belongs to another user. To dettach it send: bye"
  end

  test "signup with existing display name" do
    send_message 1, ".name John Doe"

    send_message 2, ".name John Doe"

    assert_user_exists "JohnDoe2"
    assert_user_is_logged_in 2, "JohnDoe2", "John Doe"
    assert_messages_sent_to 2, [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe2) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]

    send_message 4, ".name John Doe"

    assert_user_exists "JohnDoe3"
    assert_user_is_logged_in 4, "JohnDoe3", "John Doe"
    assert_messages_sent_to 4, [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe3) and the following password: MockPassword",
      "To send messages to a group, you must first join one. Send: join GROUP"
    ]
  end

  test "signup with fixed country and carrier" do
    # TODO
  end

  test "signup reserved name" do
    send_message 1, ".name whois"
    assert_messages_sent_to 1, "You cannot signup as 'whois' because it is a reserved name."
    assert_user_doesnt_exist 'who'
  end

  test "signup name too short" do
    send_message 1, ".name a"
    assert_messages_sent_to 1, "You cannot signup as 'a' because it is too short (minimum is 2 characters)."
    assert_user_doesnt_exist 'a'
  end

  # TODO test signup when already logged in

end
