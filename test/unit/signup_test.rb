# coding: utf-8

require 'unit/node_test'

class SignupTest < NodeTest
  test "signup" do
    assert_user_doesnt_exist "JohnDoe"

    send_message 1, ".name John Doe"

    assert_user_exists "JohnDoe"
    assert_user_is_logged_in "sms://1", "JohnDoe", "John Doe"
    assert_messages_sent_to "sms://1", [
      T.welcome_to_geochat('John Doe'),
      T.remember_you_can_log_in('JohnDoe', 'MockPassword'),
      T.to_send_message_to_a_group_you_must_first_join_one
    ]
  end

  test "signup already logged in" do
    send_message 1, ".name John Doe"

    send_message 1, ".name John Doe"
    assert_messages_sent_to "sms://1", T.device_belongs_to_another_user
  end

  test "signup with existing display name" do
    send_message 1, ".name John Doe"

    send_message 2, ".name John Doe"

    assert_user_exists "JohnDoe2"
    assert_user_is_logged_in 2, "JohnDoe2", "John Doe"
    assert_messages_sent_to 2, [
      T.welcome_to_geochat('John Doe'),
      T.remember_you_can_log_in('JohnDoe2', 'MockPassword'),
      T.to_send_message_to_a_group_you_must_first_join_one
    ]

    send_message 4, ".name John Doe"

    assert_user_exists "JohnDoe3"
    assert_user_is_logged_in 4, "JohnDoe3", "John Doe"
    assert_messages_sent_to 4, [
      T.welcome_to_geochat('John Doe'),
      T.remember_you_can_log_in('JohnDoe3', 'MockPassword'),
      T.to_send_message_to_a_group_you_must_first_join_one
    ]
  end

  test "signup with fixed country and carrier" do
    # TODO
  end

  test "signup reserved name" do
    send_message 1, ".name whois"
    assert_messages_sent_to 1, T.cannot_signup_name_reserved('whois')
    assert_user_doesnt_exist 'who'
  end

  test "signup name too short" do
    send_message 1, ".name a"
    assert_messages_sent_to 1, T.cannot_signup_name_too_short('a')
    assert_user_doesnt_exist 'a'
  end

  # TODO test signup when already logged in

end
