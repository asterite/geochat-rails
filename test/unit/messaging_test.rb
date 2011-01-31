# coding: utf-8

require 'unit/pipeline_test'

class MessagingTest < PipelineTest
  test "send message to group" do
    create_users 1..4

    send_message 1, "create group Group1"
    send_message 2..4, "join Group1"

    send_message 1, "Hello!"

    assert_messages_sent_to 2..4, "User1: Hello!"
    assert_message_saved "User1", "Group1", "Hello!"
  end

  test "send message to group explicitly with location update" do
    create_users 1..4
    send_message 1, "create group Group1"
    send_message 2..4, "join Group1"

    Geocoder.expects(:locate).with('santiago de chile').returns([-33.42536, -70.566466])
    send_message 1, "@Group1 at santiago de chile"

    assert_messages_sent_to 1, "Your location was successfully updated to santiago de chile (lat: -33.42536, lon: -70.566466)"
    assert_messages_sent_to 2..4, "User1: at santiago de chile (lat: -33.42536, lon: -70.566466)"
    assert_message_saved "User1", "Group1", "at santiago de chile (lat: -33.42536, lon: -70.566466)"
  end

  test "send message to group that does not exist" do
    create_users 1

    send_message 1, "@GroupTwo Hello!"
    assert_messages_sent_to 1, "The group GroupTwo does not exist."
    assert_no_messages_saved
  end

  test "send message to nochat group" do
    create_users 1, 2

    send_message 1, "create group Group1 nochat"
    send_message 2, "join Group1"

    send_message 1, "Hello!"
    assert_no_messages_sent
    assert_message_saved "User1", "Group1", "Hello!"
  end

  test "send blast message to nochat group" do
    create_users 1, 2

    send_message 1, "create group Group1 nochat"
    send_message 2, "join Group1"

    send_message 1, "! Hello"
    assert_messages_sent_to 2, "User1: Hello"
    assert_message_saved "User1", "Group1", "Hello"
  end

  test "send message to other group" do
    create_users 1, 2

    send_message 1, "create group Group1"
    send_message 1, "create group Group2"

    send_message 2, "join Group1"
    send_message 2, "join Group2"

    send_message 1, "Group2 Hello!"
    assert_messages_sent_to 2, "[Group2] User1: Hello!"
    assert_message_saved "User1", "Group2", "Hello!"
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

  test "send message to disabled group" do
    create_users 1, 2
    create_group 1, "Group1"
    send_message 2, "join Group1"

    disable_group "Group1"
    send_message 1, "hello"
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

  test "send message targeted to invisible public group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 1, "@Group2 Hello!"
    assert_messages_sent_to 1, "Welcome User1 to Group2. Send 'Group2 Hello group!'"
    assert_messages_sent_to 2, "User1: Hello!"
    assert_group_exists "Group2", "User1", "User2"
  end

  test "send message not targeted to invisible public group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 1, "Group2 Hello!"
    assert_no_messages_sent_to 1
    assert_group_exists "Group2", "User2"
  end

  test "send message to user" do
    create_users 1..4
    create_group 1, "Group1"

    send_message 2..3, "join Group1"

    send_message 1, "@User2 Hello!"
    assert_messages_sent_to 2, "User1 only to you: Hello!"
    assert_no_messages_sent_to 1, 3, 4
    assert_message_saved "User1", "Group1", "Hello!"
  end

  ["group2 @User2 Hello!",
    "@User2 @group2 Hello!",
    "@group2 @User2 Hello!"].each do |msg|
    test "send message to user explicit group with message #{msg}" do
      create_users 1..4
      create_group 1, "Group1"
      create_group 1, "Group2"

      send_message 2..4, "join Group1"
      send_message 2..4, "join Group2"

      send_message 1, msg
      assert_messages_sent_to 2, "[Group2] User1 only to you: Hello!"
      assert_no_messages_sent_to 1, 3, 4
      assert_message_saved "User1", "Group2", "Hello!"
    end
  end

  test "send message to user fails no common group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 1, "@User2 Hello!"
    assert_messages_sent_to 1, "You can't send a message to user User2 because you don't share a common group"
    assert_no_messages_sent_to 2
    assert_no_messages_saved
  end

  test "send message to user user fails explicit group" do
    create_users 1..4
    create_group 1, "Group1"
    create_group 1, "Group2"

    send_message 2, "join Group1"
    send_message 3..4, "join Group1"
    send_message 3..4, "join Group2"

    send_message 1, "Group2 @User2 Hello!"
    assert_messages_sent_to 1, "You can't send a message to user User2 via group Group2 because he/she does not belong to it"
    assert_no_messages_sent_to 2, 3, 4
    assert_no_messages_saved
  end

  test "forward owners" do
    create_users 1, 2, 3

    send_message 1, "create group Group1 nochat"
    set_forward_owners "Group1"

    send_message 2..3, "join Group1"

    send_message 2, "Hello!"
    assert_messages_sent_to 1, "User2: Hello!"
    assert_no_messages_sent_to 3
    assert_message_saved "User2", "Group1", "Hello!"
  end

  test "forward owners many groups" do
    create_users 1, 2, 3

    send_message 1, "create group Group1 nochat"
    send_message 1, "create group Group2"
    set_forward_owners "Group1"

    send_message 2..3, "join Group1"

    send_message 2, "Hello!"
    assert_messages_sent_to 1, "[Group1] User2: Hello!"
    assert_no_messages_sent_to 3
    assert_message_saved "User2", "Group1", "Hello!"
  end

  test "forward owners direct message" do
    create_users 1, 2, 3

    send_message 1, "create group Group1 nochat"
    set_forward_owners "Group1"

    send_message 2..3, "join Group1"

    send_message 2, "@User3 Hello!"
    assert_messages_sent_to 1, "User2 only to User3: Hello!"
    assert_messages_sent_to 3, "User2 only to you: Hello!"
    assert_message_saved "User2", "Group1", "Hello!"
  end

  test "forward owners direct message to owner" do
    create_users 1..4

    send_message 1, "create group Group1 nochat"
    send_message 4, "join Group1"
    send_message 1, "owner User4"

    set_forward_owners "Group1"

    send_message 2..3, "join Group1"

    send_message 2, "@User4 Hello!"
    assert_messages_sent_to 1, "User2 only to User4: Hello!"
    assert_messages_sent_to 4, "User2 only to you: Hello!"
    assert_message_saved "User2", "Group1", "Hello!"
  end

  test "send message does not belong to group" do
    create_users 1
    send_message 1, "Hello!"
    assert_messages_sent_to 1, "You don't belong to any group yet. To join a group send: join groupalias"
  end

  test "send message no default group" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "create Group2"

    send_message 1, "Hello!"
    assert_messages_sent_to 1, "You don't have a default group so prefix messages with a group (for example: groupalias Hello!) or set your default group with: #my group groupalias"
  end

  test "send message not logged in" do
    send_message 1, "Hello"
    assert_messages_sent_to 1, 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

end

