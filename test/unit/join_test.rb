# coding: utf-8

require 'unit/node_test'

class JoinTest < NodeTest
  test "accept invite" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "invite User2"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, T.welcome_to_first_group('User2', 'Group1'), :group => 'Group1'
    assert_messages_sent_to 1, T.user_has_accepted_your_invitation('User2', 'Group1'), :group => 'Group1'
    assert_group_exists "Group1", "User1", "User2"
  end

  test "join not allowed if not invited but later joined automatically if invited" do
    create_users 1, 2

    send_message 1, "create group Group1"
    set_requires_approval_to_join 'Group1'

    send_message 2, "join Group1"
    assert_messages_sent_to 2, T.group_requires_approval('Group1')
    assert_messages_sent_to 1, T.invitation_pending_for_approval('User2', 'Group1'), :group => 'Group1'
    assert_pending_approval "Group1", "User2"
    assert_group_exists "Group1", "User1"

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 2, T.welcome_to_first_group('User2', 'Group1'), :group => 'Group1'
    assert_messages_sent_to 1, T.users_are_now_members_of_group('User2', 'Group1'), :group => 'Group1'
    assert_group_exists "Group1", "User1", "User2"
  end

  test "join not allowed if not invited but later joined automatically if invited many owners" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_approval_to_join "Group1"
    send_message 1, "invite User3"
    send_message 3, "join Group1"
    send_message 1, "owner User3"

    assert_group_owners "Group1", "User1", "User3"

    send_message 2, "join Group1"
    assert_pending_approval "Group1", "User2"
    assert_group_exists "Group1", "User1", "User3"
    assert_messages_sent_to 2, T.group_requires_approval('Group1')
    assert_messages_sent_to [1, 3], T.invitation_pending_for_approval('User2', 'Group1'), :group => 'Group1'

    send_message 3, "invite User2"
    assert_messages_sent_to 2, T.welcome_to_first_group('User2', 'Group1'), :group => 'Group1'
    assert_messages_sent_to 3, T.users_are_now_members_of_group('User2', 'Group1'), :group => 'Group1'
    assert_group_exists "Group1", "User1", "User2", "User3"
  end

  test "join group that does not require approval" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 2, "join Group1"
    assert_messages_sent_to 2, T.welcome_to_first_group('User2', 'Group1'), :group => 'Group1'
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists
  end

  test "invite when not owner" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_approval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 2, "invite User3"
    assert_invite_suggestion_exists "Group1", "User3"
    assert_messages_sent_to 3, T.user_has_invited_you('User2', 'Group1')
    assert_messages_sent_to 2, T.invitations_sent_to_users('User3'), :group => 'Group1'

    send_message 3, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_pending_approval "Group1", "User3"
    assert_messages_sent_to 3, T.group_requires_approval('Group1')
    assert_messages_sent_to 1, T.invitation_pending_for_approval('User3', 'Group1'), :group => 'Group1'

    send_message 1, "invite User3"
    assert_group_exists "Group1", "User1", "User2", "User3"
    assert_messages_sent_to 3, T.welcome_to_first_group('User3', 'Group1'), :group => 'Group1'
    assert_messages_sent_to 1, T.users_are_now_members_of_group('User3', 'Group1'), :group => 'Group1'
    assert_no_invite_exists
  end

  test "invite when not owner, other side" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_approval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 2, "invite User3"
    assert_invite_suggestion_exists "Group1", "User3"
    assert_messages_sent_to 3, T.user_has_invited_you('User2', 'Group1')
    assert_messages_sent_to 2, T.invitations_sent_to_users('User3'), :group => 'Group1'

    send_message 1, "invite User3"
    assert_group_exists "Group1", "User1", "User2"
    assert_invite_exists "Group1", "User3"
    assert_messages_sent_to 1, T.invitations_sent_to_users('User3'), :group => 'Group1'

    send_message 3, "join Group1"
    assert_group_exists "Group1", "User1", "User2", "User3"
    assert_messages_sent_to 3, T.welcome_to_first_group('User3', 'Group1'), :group => 'Group1'
    assert_no_invite_exists
  end

  test "join and invite from not owner" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    set_requires_approval_to_join "Group1"

    send_message 1, "invite User2"
    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists

    send_message 3, "join Group1"
    send_message 2, "invite User3"
    assert_messages_sent_to 2, T.invitations_sent_to_users('User3'), :group => 'Group1'
    assert_messages_sent_to 3, T.user_has_invited_you('User2', 'Group1')
    assert_group_exists "Group1", "User1", "User2"

    send_message 1, "invite User3"
    assert_messages_sent_to 3, T.welcome_to_first_group('User3', 'Group1'), :group => 'Group1'
    assert_messages_sent_to 1, T.users_are_now_members_of_group('User3', 'Group1'), :group => 'Group1'
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
    assert_messages_sent_to 2, T.welcome_to_non_first_group('User2', 'Group2'), :group => 'Group2'
  end

  test "join not logged in" do
    send_message 1, "join Foo"
    assert_not_logged_in_message_sent_to 1
  end

end
