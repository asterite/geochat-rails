# coding: utf-8

require 'unit/node_test'

class SignupAndJoinTest < NodeTest
  test "signup and join group that does not require approval" do
    create_users 1

    send_message 1, "create group Group1"

    send_message 2, "User2 ! Group1"
    assert_messages_sent_to 2, [
      T.welcome_to_geochat('User2'),
      T.remember_you_can_log_in('User2', 'MockPassword'),
      T.welcome_to_group('User2', 'Group1')
    ]
    assert_group_exists "Group1", "User1", "User2"
  end

  test "signup and join with join keyword after being invited" do
    create_users 1

    send_message 1, "create group Group1"
    send_message 1, "Group1 +2"

    send_message 2, "User2 join Group1"
    assert_messages_sent_to 2, [
      T.welcome_to_geochat('User2'),
      T.remember_you_can_log_in('User2', 'MockPassword'),
      T.welcome_to_group('User2', 'Group1')
    ]
    assert_group_exists "Group1", "User1", "User2"

    assert_user_was_not_created_from_invite "User2"
  end

  test "signup and join with mobile number" do
    send_message 1, ".name 1234"
    send_message 2, ".name 2345"
    send_message 1, "create group Group1"

    send_message 1, "invite 2345"
    assert_messages_sent_to 2, T.user_has_invited_you('1234', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('2345')
    assert_invite_exists "Group1", "2345"
    assert_group_exists "Group1", "1234"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, T.welcome_to_group('2345', 'Group1')
    assert_group_exists "Group1", "1234", "2345"
  end

  test "signup and join when logged in is just a message" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 2, "join Group1"

    send_message 1, "Hello ! World"
    assert_messages_sent_to 2, "User1: Hello ! World"
    assert_message_saved "User1", "Group1", "Hello ! World"
  end
end
