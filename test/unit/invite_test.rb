# coding: utf-8

require 'unit/pipeline_test'

class InviteTest < PipelineTest
  test "invite" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "invite User2"

    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2"
  end

  test "invite with group as target" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite Group1 User2"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2"
  end

  test "invite with group as target inverted" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite User2 Group1"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2"
  end

  test "invite many" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"

    send_message 1, "invite User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2, User3"
  end

  test "invite many targeted" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"

    send_message 1, "invite Group1 User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2, User3"
  end

  test "invite to default group" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"
    send_message 1, "#my group Group1"

    send_message 1, "invite User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to User2, User3"
  end

  test "invite to other group" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "invite Group2 User2 User3"
    assert_invite_exists "Group2", "User2", "User3"
    assert_messages_sent_to 2, "User1 has invited you to group Group2. You can join by sending: join Group2"
    assert_messages_sent_to 2, "User1 has invited you to group Group2. You can join by sending: join Group2"
    assert_messages_sent_to 1, "Invitation/s sent to User2, User3"
  end

  test "invite to other group simpler syntax" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "Group2 +User2 +User3"
    assert_invite_exists "Group2", "User2", "User3"
    assert_messages_sent_to 2, "User1 has invited you to group Group2. You can join by sending: join Group2"
    assert_messages_sent_to 2, "User1 has invited you to group Group2. You can join by sending: join Group2"
    assert_messages_sent_to 1, "Invitation/s sent to User2, User3"
  end

  test "invite non existing user" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite User3"
    assert_no_invite_exists
    assert_messages_sent_to 1, "Could not find a registered user 'User3' for your invitation."
  end

  test "invite without groups" do
    create_users 1, 2

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 1, "You don't belong to any group yet. To join a group send: join groupalias"
  end

  test "invite without default group" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 1, "You must specify a group to invite the users to, or set a default group."
  end

  test "invite new mobile number" do
    create_users 1

    send_message 1, "create group Group1"

    send_message 1, "Group1 +5591112345678"
    assert_user_was_created_from_invite "5591112345678"
    assert_group_exists "Group1", "User1"
    assert_invite_exists "Group1", "5591112345678"
    assert_messages_sent_to 5591112345678, "Welcome to GeoChat's group Group1. Tell us your name and join the group by sending: YOUR_NAME join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to 5591112345678"

    send_message 5591112345678, "John Doe > Group1"
    assert_user_doesnt_exist "5591112345678"
    assert_user_exists "JohnDoe"
    assert_user_was_not_created_from_invite "JohnDoe"
    assert_group_exists "Group1", "User1", "JohnDoe"
    assert_messages_sent_to 5591112345678, [
      "Welcome John Doe to GeoChat! Send HELP for instructions. http://geochat.instedd.org",
      "Remember you can log in to http://geochat.instedd.org by entering your login (JohnDoe) and the following password: MockPassword",
      "Welcome John Doe to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    ]
  end

  test "invite existing mobile number" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "Group1 +2"
    assert_user_doesnt_exist "2"
    assert_user_was_not_created_from_invite "User2"
    assert_group_exists "Group1", "User1"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to 2"

    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
  end

  test "invite existing mobile number but user does signup" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "Group1 +2"
    assert_user_doesnt_exist "2"
    assert_user_was_not_created_from_invite "User2"
    assert_group_exists "Group1", "User1"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, "User1 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to 2"

    send_message 2, "John Doe > Group1"
    assert_group_exists "Group1", "User1"
    assert_messages_sent_to 2, "This device already belongs to another user. To dettach it send: bye"
  end

  test "invite plus number group" do
    send_message 1, ".name 1234"
    send_message 2, ".name 2345"
    send_message 1, "create group Group1"

    send_message 1, "invite +2345 Group1"
    assert_messages_sent_to 2, "1234 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 1, "Invitation/s sent to 2345"

    assert_invite_exists "Group1", "2345"
    assert_group_exists "Group1", "1234"
  end

  test "invite not logged in" do
    send_message 1, "invite Foo"
    assert_not_logged_in_message_sent_to 1
  end
end
