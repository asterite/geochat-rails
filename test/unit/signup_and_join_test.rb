# coding: utf-8

require 'unit/pipeline_test'

class SignupAndJoinTest < PipelineTest
  test "signup and join group that does not require approval" do
    create_users 1

    send_message 1, "create group Group1"

    send_message 2, "User2 ! Group1"
    assert_messages_sent_to 2, [
      "Welcome User2 to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
       "Remember you can log in to http://geochat.instedd.org by entering your login (User2) and the following password: MockPassword",
       "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    ]
    assert_group_exists "Group1", "User1", "User2"
  end

  test "signup and join with join keyword after being invited" do
    create_users 1

    send_message 1, "create group Group1"
    send_message 1, "Group1 +2"

    send_message 2, "User2 join Group1"
    assert_messages_sent_to 2, [
      "Welcome User2 to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (User2) and the following password: MockPassword",
      "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    ]
    assert_group_exists "Group1", "User1", "User2"

    assert_user_was_not_created_from_invite "User2"
  end

  test "signup and join with mobile number" do
    send_message 1, ".name 1234"
    send_message 2, ".name 2345"
    send_message 1, "create group Group1"

    send_message 1, "invite 2345"
    assert_messages_sent_to 2, "1234 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to 2345"
    assert_invite_exists "Group1", "2345"
    assert_group_exists "Group1", "1234"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, "Welcome 2345 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
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
