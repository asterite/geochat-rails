# coding: utf-8

require 'unit/pipeline_test'

class OwnerTest < PipelineTest
  ["2", "User2"].each do |user|
    ["owner #{user}", "Group1 owner #{user}", "owner Group1 #{user}", "owner #{user} Group1"].each do |msg|
      test "add group owner #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 2, "join Group1"
        assert_is_not_group_owner "Group1", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_set_as_owner('User2', 'Group1')
        assert_messages_sent_to 2, T.user_has_made_you_owner('User1', 'Group1')
        assert_group_owners "Group1", "User1", "User2"
      end

      test "add group owner user does not exist #{msg}" do
        create_users 1

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, T.user_does_not_exist(user)
        assert_group_owners "Group1", "User1"
      end

      test "add group owner user does not belong to group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, T.user_does_not_belong_to_group('User2', 'Group1')
        assert_group_owners "Group1", "User1"
      end
    end
  end

  ["2", "User2"].each do |user|
    ["Group2 owner #{user}", "owner Group2 #{user}", "owner #{user} Group2"].each do |msg|
      test "add group owner another group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, "create group Group2"
        send_message 2, "join Group1"
        send_message 2, "join Group2"
        assert_is_not_group_owner "Group2", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_set_as_owner('User2', 'Group2')
        assert_messages_sent_to 2, T.user_has_made_you_owner('User1', 'Group2')
        assert_group_owners "Group2", "User1", "User2"
      end
    end
  end

  test "add group owner group does not exist and user neither" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "owner Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist(T.a_or_b 'Group2', 'User2')
    assert_group_owners "Group1", "User1"
  end

  test "add group owner group does not exist user does" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "owner Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist('Group2')
    assert_group_owners "Group1", "User1"
  end

  test "add group owner no default group" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "owner User2"
    assert_messages_sent_to 1, T.you_must_specify_a_group_to_set_owner('User2')
    assert_group_owners "Group1", "User1"
  end

  test "add group owner not joined to a group" do
    create_users 1, 2

    send_message 1, "owner User2"
    assert_messages_sent_to 1,  T.you_dont_belong_to_any_group_yet
  end

  test "add group owner not owner" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 2, "owner User1"
    assert_messages_sent_to 2, T.you_cant_set_owner_you_are_not_owner('User1', 'Group1')
    assert_group_owners "Group1", "User1"
  end

  test "add group owner not logged in" do
    create_users 2
    send_message 1, "owner User2"
    assert_not_logged_in_message_sent_to 1
  end

  test "add group owner already owner" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, "owner User2"
    send_message 1, "owner User2"
    assert_messages_sent_to 1, T.user_already_an_owner('User2', 'Group1')
  end

  test "add group owner self owner" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "owner User1"
    assert_messages_sent_to 1, T.you_are_already_an_owner_of_group('Group1')
  end

  test "add group owner self not owner" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 2, "owner User2"
    assert_messages_sent_to 2, T.nice_try
  end

  test "add group owner does not belong to group" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "owner Group1 User1"
    assert_messages_sent_to 2, T.you_cant_set_owner_you_dont_belong_to_group('User1', 'Group1')
  end
end
