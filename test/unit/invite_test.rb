# coding: utf-8

require 'unit/pipeline_test'

class InviteTest < PipelineTest
  test "invite" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "invite User2"

    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('User2')
  end

  test "invite with group as target" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite Group1 User2"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('User2')
  end

  test "invite with group as target inverted" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite User2 Group1"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('User2')
  end

  test "invite many" do
    create_users 1, 2, 3

    send_message 1, "create Group1"

    send_message 1, "invite User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2..3, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users(['User2', 'User3'])
  end

  test "invite many targeted" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"

    send_message 1, "invite Group1 User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2..3, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users(['User2', 'User3'])
  end

  test "invite to default group" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"
    send_message 1, ".my group Group1"

    send_message 1, "invite User2 User3"
    assert_invite_exists "Group1", "User2", "User3"
    assert_messages_sent_to 2..3, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users(['User2', 'User3'])
  end

  test "invite to other group" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "invite Group2 User2 User3"
    assert_invite_exists "Group2", "User2", "User3"
    assert_messages_sent_to 2..3, T.user_has_invited_you('User1', 'Group2')
    assert_messages_sent_to 1, T.invitations_sent_to_users(['User2', 'User3'])
  end

  test "invite to other group simpler syntax" do
    create_users 1, 2, 3

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "Group2 +User2 +User3"
    assert_invite_exists "Group2", "User2", "User3"
    assert_messages_sent_to 2..3, T.user_has_invited_you('User1', 'Group2')
    assert_messages_sent_to 1, T.invitations_sent_to_users(['User2', 'User3'])
  end

  test "invite non existing user" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite User3"
    assert_no_invite_exists
    assert_messages_sent_to 1, T.could_not_find_users_for_invitation('User3')
  end

  test "invite non existing users" do
    create_users 1, 2

    send_message 1, "create group Group1"

    send_message 1, "invite User3 User4"
    assert_no_invite_exists
    assert_messages_sent_to 1, T.could_not_find_users_for_invitation(['User3', 'User4'])
  end

  test "invite without groups" do
    create_users 1, 2

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 1, T.you_dont_belong_to_any_group_yet
  end

  test "invite without default group" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 1, "invite User2"
    assert_no_invite_exists
    assert_messages_sent_to 1, T.you_must_specify_a_group_to_invite
  end

  test "invite new mobile number" do
    create_users 1

    send_message 1, "create group Group1"

    send_message 1, "Group1 +5591112345678"
    assert_user_was_created_from_invite "5591112345678"
    assert_group_exists "Group1", "User1"
    assert_invite_exists "Group1", "5591112345678"
    assert_messages_sent_to 5591112345678, T.welcome_to_group_signup_and_join('Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('5591112345678')

    send_message 5591112345678, "John Doe > Group1"
    assert_user_doesnt_exist "5591112345678"
    assert_user_exists "JohnDoe"
    assert_user_was_not_created_from_invite "JohnDoe"
    assert_group_exists "Group1", "User1", "JohnDoe"
    assert_messages_sent_to 5591112345678, [
      T.welcome_to_geochat('John Doe'),
      T.remember_you_can_log_in('JohnDoe', 'MockPassword'),
      T.welcome_to_group('John Doe', 'Group1')
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
    assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('2')

    send_message 2, "join Group1"
    assert_group_exists "Group1", "User1", "User2"
    assert_messages_sent_to 1, T.user_has_accepted_your_invitation('User2', 'Group1')
    assert_messages_sent_to 2, T.welcome_to_group('User2', 'Group1')
  end

  test "invite existing mobile number but user does signup" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "Group1 +2"
    assert_user_doesnt_exist "2"
    assert_user_was_not_created_from_invite "User2"
    assert_group_exists "Group1", "User1"
    assert_invite_exists "Group1", "User2"
    assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('2')

    send_message 2, "John Doe > Group1"
    assert_group_exists "Group1", "User1"
    assert_messages_sent_to 2, T.device_belongs_to_another_user
  end

  test "invite plus number group" do
    send_message 1, ".name 1234"
    send_message 2, ".name 2345"
    send_message 1, "create group Group1"

    send_message 1, "invite +2345 Group1"
    assert_messages_sent_to 2, T.user_has_invited_you('1234', 'Group1')
    assert_messages_sent_to 1, T.invitations_sent_to_users('2345')

    assert_invite_exists "Group1", "2345"
    assert_group_exists "Group1", "1234"
  end

  test "invite not logged in" do
    send_message 1, "invite Foo"
    assert_not_logged_in_message_sent_to 1
  end

  test "invite self" do
    create_users 1

    send_message 1, "create group Group1"
    send_message 1, "invite User1"

    assert_no_invite_exists
    assert_messages_sent_to 1, T.you_cant_invite_yourself
  end

  test "invite self many times" do
    create_users 1

    send_message 1, "create group Group1"
    send_message 1, "invite User1 User1"

    assert_no_invite_exists
    assert_messages_sent_to 1, T.you_cant_invite_yourself
  end

  test "invite from many requestors" do
    create_users 1..3
    send_message 1, "create group Group1"
    send_message 2, "join Group1"
    send_message 1..2, "invite User3"

    send_message 3, "join Group1"
    assert_messages_sent_to 1..2, T.user_has_accepted_your_invitation('User3', 'Group1')
    assert_messages_sent_to 3, T.welcome_to_group('User3', 'Group1')
    assert_no_invite_exists
  end

  test "invite many times same user" do
    create_users 1..2
    send_message 1, "create group Group1"
    send_message 1, "invite User2"
    send_message 1, "invite User2"

    assert_messages_sent_to 1, T.you_already_invited_user('User2', 'Group1')
    assert_no_messages_sent_to 2
  end

  test "invite user that already belongs to group" do
    create_users 1..2
    send_message 1, "create group Group1"
    send_message 2, "join Group1"

    send_message 1, "invite User2"
    assert_messages_sent_to 1, T.user_already_belongs_to_group('User2', 'Group1')
    assert_no_messages_sent_to 2
  end
end
