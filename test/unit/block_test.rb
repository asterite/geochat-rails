# coding: utf-8

require 'unit/pipeline_test'

class BlockTest < PipelineTest
  ["2", "User2"].each do |user|
    ["block #{user}", "Group1 block #{user}", "block Group1 #{user}", "block #{user} Group1"].each do |msg|
      test "block #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 2, "join Group1"
        assert_is_not_blocked "Group1", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_blocked('User2', 'Group1')
        assert_no_messages_sent_to 2
        assert_group_exists "Group1", "User1"
      end

      test "block user does not exist #{msg}" do
        create_users 1

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, T.user_does_not_exist(user)
        assert_group_exists "Group1", "User1"
      end
    end
  end

  ["2", "User2"].each do |user|
    ["Group2 block #{user}", "block Group2 #{user}", "block #{user} Group2"].each do |msg|
      test "block in another group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, "create group Group2"
        send_message 2, "join Group1"
        send_message 2, "join Group2"
        assert_is_not_blocked "Group2", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_blocked('User2', 'Group2')
        assert_no_messages_sent_to 2
        assert_group_exists "Group2", "User1"
      end
    end
  end

  test "block group does not exist and user neither" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "block Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist(T.a_or_b 'Group2', 'User2')
    assert_group_exists "Group1", "User1"
  end

  test "block group does not exist user does" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "block Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist('Group2')
    assert_group_exists "Group1", "User1"
  end

  test "block no default group" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "block User2"
    assert_messages_sent_to 1, T.you_must_specify_a_group_to_block('User2')
    assert_group_exists "Group1", "User1"
  end

  test "block not joined to a group" do
    create_users 1, 2

    send_message 1, "block User2"
    assert_messages_sent_to 1,  T.you_dont_belong_to_any_group_yet
  end

  test "block not owner" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 2, "block User1"
    assert_messages_sent_to 2, T.you_cant_block_you_are_not_owner('User1', 'Group1')
    assert_group_exists "Group1", "User1", "User2"
  end

  test "block not logged in" do
    create_users 2
    send_message 1, "block User2"
    assert_not_logged_in_message_sent_to 1
  end

  test "block already blocked" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, "block User2"
    send_message 1, "block User2"
    assert_messages_sent_to 1, T.user_already_blocked('User2', 'Group1')
  end

  test "block self" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "block User1"
    assert_messages_sent_to 1, T.you_cant_block_yourself
  end
end
