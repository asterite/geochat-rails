# coding: utf-8

require 'unit/pipeline_test'

class MessagingTest < PipelineTest
  test "send message to group" do
    create_users 1, 2, 3, 4

    send_message 1, "create group Group1"
    send_message 2, "join Group1"
    send_message 3, "join Group1"
    send_message 4, "join Group1"

    send_message 1, "Hello!"

    assert_messages_sent_to 2..4, "User1: Hello!"
    assert_message_saved_as_blast 1, "Group1", "Hello!"
  end

  test "send message to group explicitly with location update" do
    create_users 1, 2, 3, 4
    send_message 1, "create group Group1"
    send_message 2, "join Group1"
    send_message 3, "join Group1"
    send_message 4, "join Group1"

    Geocoder.expects(:locate).with('santiago de chile').returns([-33.42536, -70.566466])
    send_message 1, "@Group1 at santiago de chile"

    assert_messages_sent_to 1, "Your location was successfully updated to santiago de chile (lat: -33.42536, lon: -70.566466)"
    assert_messages_sent_to 2..4, "User1: at santiago de chile"
    assert_message_saved_as_blast 1, "Group1", "at santiago de chile"
  end

  test "send message to group that does not exist" do
    create_users 1

    send_message 1, "@GroupTwo Hello!"
    assert_messages_sent_to 1, "The group GroupTwo does not exist"
    assert_no_messages_saved
  end

  test "send message to nochat group" do
    create_users 1, 2

    send_message 1, "create group Group1 nochat"
    send_message 2, "join Group1"

    send_message 1, "Hello!"
    assert_no_messages_sent
    assert_message_saved_as_non_blast 1, "Group1", "Hello!"
  end

  test "send blast message to nochat group" do
    create_users 1, 2

    send_message 1, "create group Group1 nochat"
    send_message 2, "join Group1"

    send_message 1, "! Hello"
    assert_messages_sent_to 2, "User1: Hello"
    assert_message_saved_as_blast 1, "Group1", "Hello"
  end

  test "send message to other group" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 2, "join Group1"
    send_message 2, "join Group2"

    send_message 1, "Group2 Hello!"
    assert_messages_sent_to 2, "[Group2] User1: Hello!"
    assert_message_saved_as_blast 1, "Group2", "Hello!"
  end

  test "send message prefixed with invisible group" do
    create_users 1, 2, 3
    create_group 1, "Group1"
    create_group 2, "Group2"
    send_message 3, "join Group1"

    send_message 1, "Group2 hello"
    assert_messages_sent_to 3, "User1: Group2 hello"
  end

  test "send message prefixed with disabled group" do
    create_users 1, 2
    create_group 1, "Group1"
    send_message 2, "join Group1"

    disable_group "Group1"
    send_message 1, "Group1 hello"
    assert_messages_sent_to 1, "You can't send messages to Group1 because it is disabled."
    assert_no_messages_sent_to 2
  end

  test "send message prefixed with admin invited group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 2, "invite 1"

    send_message 1, "Group2 Hello"
    assert_messages_sent_to 1, "Welcome User1 to Group2. Send 'Group2 Hello group!'"
    assert_messages_sent_to 2, "User1: Hello"
    assert_group_exists "Group2", "User1", "User2"
    assert_no_invite_exists
  end

  test "send message prefixed with non-admin invited public group (first group)" do
    create_users 1, 2
    create_group 1, "Group1"
    send_message 1, "invite 2"

    send_message 2, "Group1 Hello"
    assert_messages_sent_to 2, "Welcome User2 to group Group1. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    assert_messages_sent_to 1, "User2: Hello"
    assert_group_exists "Group1", "User1", "User2"
    assert_no_invite_exists
  end

  test "send message prefixed with non-admin invited public group (second group)" do
    create_users 1, 2, 3
    create_group 1, "Group1"
    create_group 2, "Group2"
    send_message 3, "join Group2"

    send_message 3, "invite 1"

    send_message 1, "Group2 Hello"
    assert_messages_sent_to 1, "Welcome User1 to Group2. Send 'Group2 Hello group!'"
    assert_messages_sent_to 2..3, "User1: Hello"
    assert_group_exists "Group2", "User1", "User2", "User3"
    assert_no_invite_exists
  end

  test "send message prefixed with non-admin invited private group" do
    create_users 1, 2, 3
    create_group 1, "Group1"
    create_group 2, "Group2"
    send_message 3, "join Group2"
    set_requires_aproval_to_join "Group2"

    send_message 3, "invite 1"

    send_message 1, "Group2 Hello"
    assert_messages_sent_to 1, "You can not send messages to the group Group2 as your invitation has not yet been approved by an admin."
    assert_no_messages_sent_to 2..3
    assert_group_exists "Group2", "User2", "User3"
    assert_invite_suggestion_exists "Group2", "User1"
  end

  test "send message targeted to invisible private group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"
    set_requires_aproval_to_join "Group2"

    send_message 1, "@Group2 Hello"
    assert_messages_sent_to 1, "You can not send messages to the group Group2 because you are not a member or the group requires approval to join. To request an invitation send: join Group2"
    assert_no_messages_sent_to 2
  end

end

