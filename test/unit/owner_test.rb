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
        assert_messages_sent_to 1, "The user User2 was successfully set as owner of group Group1."
        assert_messages_sent_to 2, "User1 has made you owner of group Group1."
        assert_group_owners "Group1", "User1", "User2"
      end

      test "add group owner user does not exist #{msg}" do
        create_users 1

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, "The user #{user} does not exist."
        assert_group_owners "Group1", "User1"
      end

      test "add group owner user does not belong to group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, "The user User2 does not belong to group Group1."
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
        assert_messages_sent_to 1, "The user User2 was successfully set as owner of group Group2."
        assert_messages_sent_to 2, "User1 has made you owner of group Group2."
        assert_group_owners "Group2", "User1", "User2"
      end
    end
  end

  test "add group owner group does not exist and user neither" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "owner Group2 User2"
    assert_messages_sent_to 1, "The group Group2 or User2 does not exist."
    assert_group_owners "Group1", "User1"
  end

  test "add group owner group does not exist user does" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "owner Group2 User2"
    assert_messages_sent_to 1, "The group Group2 does not exist."
    assert_group_owners "Group1", "User1"
  end

  test "add group owner no default group" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "owner User2"
    assert_messages_sent_to 1, "You must specify a group to set User2 as an owner, or set a default group."
    assert_group_owners "Group1", "User1"
  end

  test "add group owner not joined to a group" do
    create_users 1, 2

    send_message 1, "owner User2"
    assert_messages_sent_to 1,  "You don't belong to any group yet. To join a group send: join groupalias"
  end
end
