# coding: utf-8

require 'unit/node_test'

class AdminTest < NodeTest
  ["2", "User2"].each do |user|
    ["admin #{user}", "Group1 admin #{user}", "admin Group1 #{user}", "admin #{user} Group1"].each do |msg|
      test "add group admin #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 2, "join Group1"
        assert_is_not_group_admin "Group1", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_set_as_admin('User2', 'Group1'), :group => 'Group1'
        assert_messages_sent_to 2, T.user_has_made_you_admin('User1', 'Group1'), :group => 'Group1'
        assert_group_admins "Group1", "User1", "User2"
      end

      test "add group admin user does not exist #{msg}" do
        create_users 1

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, T.user_does_not_exist(user), :group => 'Group1'
        assert_group_admins "Group1", "User1"
      end

      test "add group admin user does not belong to group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, msg
        assert_messages_sent_to 1, T.user_does_not_belong_to_group('User2', 'Group1'), :group => 'Group1'
        assert_group_admins "Group1", "User1"
      end
    end
  end

  ["2", "User2"].each do |user|
    ["Group2 admin #{user}", "admin Group2 #{user}", "admin #{user} Group2"].each do |msg|
      test "add group admin another group #{msg}" do
        create_users 1, 2

        send_message 1, "create group Group1"
        send_message 1, "create group Group2"
        send_message 2, "join Group1"
        send_message 2, "join Group2"
        assert_is_not_group_admin "Group2", "User2"

        send_message 1, msg
        assert_messages_sent_to 1, T.user_set_as_admin('User2', 'Group2'), :group => 'Group2'
        assert_messages_sent_to 2, T.user_has_made_you_admin('User1', 'Group2'), :group => 'Group2'
        assert_group_admins "Group2", "User1", "User2"
      end
    end
  end

  test "add group admin group does not exist and user neither" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "admin Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist(T.a_or_b 'Group2', 'User2')
    assert_group_admins "Group1", "User1"
  end

  test "add group admin group does not exist user does" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "admin Group2 User2"
    assert_messages_sent_to 1, T.group_does_not_exist('Group2')
    assert_group_admins "Group1", "User1"
  end

  test "add group admin no default group" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "admin User2"
    assert_messages_sent_to 1, T.you_must_specify_a_group_to_set_admin('User2')
    assert_group_admins "Group1", "User1"
  end

  test "add group admin not joined to a group" do
    create_users 1, 2

    send_message 1, "admin User2"
    assert_messages_sent_to 1,  T.you_dont_belong_to_any_group_yet
  end

  test "add group admin not admin" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 2, "admin User1"
    assert_messages_sent_to 2, T.you_cant_set_admin_you_are_not_admin('User1', 'Group1'), :group => 'Group1'
    assert_group_admins "Group1", "User1"
  end

  test "add group admin not logged in" do
    create_users 2
    send_message 1, "admin User2"
    assert_not_logged_in_message_sent_to 1
  end

  test "add group admin already admin" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, "admin User2"
    send_message 1, "admin User2"
    assert_messages_sent_to 1, T.user_already_an_admin('User2', 'Group1'), :group => 'Group1'
  end

  test "add group admin self admin" do
    create_users 1

    send_message 1, "create Group1"
    send_message 1, "admin User1"
    assert_messages_sent_to 1, T.you_are_already_an_admin_of_group('Group1'), :group => 'Group1'
  end

  test "add group admin self not admin" do
    create_users 1, 2

    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 2, "admin User2"
    assert_messages_sent_to 2, T.nice_try, :group => 'Group1'
  end

  test "add group admin does not belong to group" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "admin Group1 User1"
    assert_messages_sent_to 2, T.you_cant_set_admin_you_dont_belong_to_group('User1', 'Group1')
  end
end
