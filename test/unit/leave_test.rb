# coding: utf-8

require 'unit/pipeline_test'

class LeaveTest < PipelineTest
  test "leave with single group" do
    create_users 1, 2
    send_message 1, "create group Group1"
    send_message 2, "join Group1"

    send_message 2, "leave Group1"
    assert_messages_sent_to 2, "Good bye User2 from your only group Group1. To join another group send: join groupalias"
    assert_group_exists "Group1", "User1"
  end

  test "leave with two groups" do
    create_users 1, 2
    send_message 1, "create group Group1"
    send_message 1, "create group Group2"
    send_message 2, "join Group1"
    send_message 2, "join Group2"

    send_message 2, "leave Group1"
    assert_messages_sent_to 2, "Good bye User2 from group Group1. Now your default group is Group2."
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
    assert_messages_sent_to 2, "Good bye User2 from group Group1."
    assert_group_exists "Group1", "User1"
  end

  test "leave group does not exist" do
    create_users 1
    send_message 1, "leave Group1"
    assert_messages_sent_to 1, "The group Group1 does not exist."
  end

  test "leave group does not belong to" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "leave Group1"
    assert_messages_sent_to 2, "You can't leave group Group1 because you don't belong to it."
  end

  test "leave group only owner" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "leave Group1"
    assert_messages_sent_to 1, "You can't leave group Group1 because you are its only owner."
  end

  test "leave group not only owner" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"
    send_message 1, "owner User2"

    send_message 1, "leave Group1"
    assert_messages_sent_to 1, "Good bye User1 from your only group Group1. To join another group send: join groupalias"
  end
end
