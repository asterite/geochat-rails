# coding: utf-8

require 'unit/pipeline_test'

class CreateGroupTest < PipelineTest
  test "create group" do
    create_users 1

    send_message 1, "create group Group1"
    assert_group_exists "Group1", "User1"

    assert_messages_sent_to 1, "Group 'Group1' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: Group1 +PHONE_NUMBER"
  end

  test "create group already exists" do
    create_users 1, 2
    create_group 1, "Group1"

    send_message 2, "create group Group1"
    assert_group_exists "Group1", "User1"

    assert_messages_sent_to 2, "The group Group1 already exists. Please specify another alias."
  end

  test "create group with a non user" do
    send_message 1, "create group Group1"
    assert_not_logged_in_message_sent_to 1
  end

  test "create group with a logged off user" do
    create_users 1
    send_message 1, "#bye"

    send_message 1, "create group Group1"
    assert_not_logged_in_message_sent_to 1
  end
end
