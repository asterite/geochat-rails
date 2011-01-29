# coding: utf-8

require 'unit/pipeline_test'

class JoinTest < PipelineTest
  test "accept invite" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "invite User2"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 1, "User2 has just accepted your invitation to join Group1."
    assert_group_exists "Group1", "User1", "User2"
  end

  test "join not allowed if not invited but later joined automatically if invited" do
    create_users 1, 2

    send_message 1, "create group Group1"
    set_requires_aproval_to_join 'Group1'

    send_message 2, "join Group1"
    assert_messages_sent_to 1, "An invitation is pending for approval. To approve it send: invite Group1 User2"
    assert_messages_sent_to 2, "Group Group1 requires approval to join by an Administrator. We will let you know when you can start sending messages."
    assert_pending_approval "Group1", "User2"
    assert_group_exists "Group1", "User1"

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 1, "User2 is now a member of group Group1."
    assert_group_exists "Group1", "User1", "User2"
  end

  test "join not allowed if not invited but later joined automatically if invited many owners" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_aproval_to_join "Group1"
    send_message 1, "invite User3"
    send_message 3, "join Group1"
    send_message 1, "owner User3"

    assert_group_owners "Group1", "User1", "User3"

    send_message 2, "join Group1"
    assert_pending_approval "Group1", "User2"
    assert_group_exists "Group1", "User1", "User3"
    assert_messages_sent_to 1, "An invitation is pending for approval. To approve it send: invite Group1 User2"
    assert_messages_sent_to 3, "An invitation is pending for approval. To approve it send: invite Group1 User2"
    assert_messages_sent_to 2, "Group Group1 requires approval to join by an Administrator. We will let you know when you can start sending messages."

    send_message 3, "invite User2"
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 3, "User2 is now a member of group Group1."
    assert_group_exists "Group1", "User1", "User2", "User3"
  end

  test "join group that does not require approval" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists
  end

  test "invite when not owner" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_aproval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 2, "invite User3"
    assert_invite_suggestion_exists "Group1", "User3"
    assert_messages_sent_to 3, "User2 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 2, "Invitation/s sent to User3"

    send_message 3, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_pending_approval "Group1", "User3"
    assert_messages_sent_to 1, "An invitation is pending for approval. To approve it send: invite Group1 User3"
    assert_messages_sent_to 3, "Group Group1 requires approval to join by an Administrator. We will let you know when you can start sending messages."

    send_message 1, "invite User3"
    assert_group_exists "Group1", "User1", "User2", "User3"
    assert_messages_sent_to 3, "Welcome User3 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 1, "User3 is now a member of group Group1."
    assert_no_invite_exists
  end

  test "invite when not owner, other side" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_aproval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 2, "invite User3"
    assert_invite_suggestion_exists "Group1", "User3"
    assert_messages_sent_to 3, "User2 has invited you to group Group1. You can join by sending: join Group1"
    assert_messages_sent_to 2, "Invitation/s sent to User3"

    send_message 1, "invite User3"
    assert_group_exists "Group1", "User1", "User2"
    assert_invite_exists "Group1", "User3"
    assert_messages_sent_to 1, "Invitation/s sent to User3"

    send_message 3, "join Group1"
    assert_group_exists "Group1", "User1", "User2", "User3"
    assert_messages_sent_to 3, "Welcome User3 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_no_invite_exists
  end

  test "join and invite from not owner" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_aproval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 3, "join Group1"
    send_message 2, "invite User3"
    assert_messages_sent_to 2, "Invitation/s sent to User3"
    assert_no_messages_sent_to 3
    assert_group_exists "Group1", "User1", "User2"

    send_message 1, "invite User3"
    assert_messages_sent_to 3, "Welcome User3 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 1, "User3 is now a member of group Group1."
    assert_no_invite_exists
    assert_group_exists "Group1", "User1", "User2", "User3"
  end

  test "send welcome message with group if joined and no default group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 1, "Group2"
    send_message 2, "join Group1"
    send_message 1, "invite Group2 2"

    send_message 2, "join Group2"
    assert_messages_sent_to 2, "Welcome User2 to Group2. Send 'Group2 Hello group!'"
  end

  test "join not logged in" do
    send_message 1, "join Foo"
    assert_not_logged_in_message_sent_to 1
  end

end
