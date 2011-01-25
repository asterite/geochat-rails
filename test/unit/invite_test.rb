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
end
