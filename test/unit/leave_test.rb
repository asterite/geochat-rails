# coding: utf-8

require 'unit/node_test'

class LeaveTest < NodeTest
  test "leave with single group" do
    create_users 1, 2
    send_message 1, "create group Group1"
    send_message 2, "join Group1"

    send_message 2, "leave Group1"
    assert_messages_sent_to 2, T.good_bye_from_only_group('User2', 'Group1')
    assert_group_exists "Group1", "User1"
  end

  test "leave with two groups" do
    create_users 1, 2
    send_message 1, "create group Group1"
    send_message 1, "create group Group2"
    send_message 2, "join Group1"
    send_message 2, "join Group2"

    send_message 2, "leave Group1"
    assert_messages_sent_to 2, T.good_bye_from_second_group('User2', 'Group1', 'Group2')
    assert_group_exists "Group1", "User1"
  end

  test "leave with three groups" do
    create_users 1, 2
    send_message 1, "create group Group1"
    send_message 1, "create group Group2"
    send_message 1, "create group Group3"
    send_message 2, "join Group1"
    send_message 2, "join Group2"
    send_message 2, "join Group3"

    send_message 2, "leave Group1"
    assert_messages_sent_to 2, T.good_bye_from_more_than_two_groups('User2', 'Group1')
    assert_group_exists "Group1", "User1"
  end

  test "leave group does not exist" do
    create_users 1
    send_message 1, "leave Group1"
    assert_messages_sent_to 1, T.group_does_not_exist('Group1')
  end

  test "leave group does not belong to" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "leave Group1"
    assert_messages_sent_to 2, T.you_cant_leave_group_because_you_dont_belong_to_it('Group1')
  end

  test "leave group only owner" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "leave Group1"
    assert_messages_sent_to 1, T.you_cant_leave_group_because_you_are_its_only_owner('Group1')
  end

  test "leave group not only owner" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 1, "owner User2"

    send_message 1, "leave Group1"
    assert_messages_sent_to 1, T.good_bye_from_only_group('User1', 'Group1')
  end

  test "leave not logged in" do
    create_users 1
    send_message 1, "create Group1"
    send_message 2, "leave Group1"
    assert_not_logged_in_message_sent_to 2
  end
end
