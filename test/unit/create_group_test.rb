# coding: utf-8

require 'unit/pipeline_test'

class CreateGroupTest < PipelineTest
  test "create group" do
    create_users 1

    send_message 1, "create group Group1"
    assert_group_exists "Group1", "User1"

    assert_messages_sent_to 1, T.group_created('Group1')
  end

  test "create group already exists" do
    create_users 1, 2
    create_group 1, "Group1"

    send_message 2, "create group Group1"
    assert_group_exists "Group1", "User1"

    assert_messages_sent_to 2, T.group_already_exists('Group1')
  end

  test "create group with a non user" do
    send_message 1, "create group Group1"
    assert_not_logged_in_message_sent_to 1
  end

  test "create group with a logged off user" do
    create_users 1
    send_message 1, "bye"

    send_message 1, "create group Group1"
    assert_not_logged_in_message_sent_to 1
  end

  test "create group fails reserved name" do
    create_users 1
    send_message 1, "create group bye"
    assert_messages_sent_to 1, T.cannot_create_group_name_reserved('bye')
    assert !Group.find_by_alias('bye')
  end

  test "create group fails too short" do
    create_users 1
    send_message 1, "create group a"
    assert_messages_sent_to 1, T.cannot_create_group_name_too_short('a')
    assert !Group.find_by_alias('bye')
  end
end
