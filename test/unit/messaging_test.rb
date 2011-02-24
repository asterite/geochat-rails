# coding: utf-8

require 'unit/node_test'

class MessagingTest < NodeTest
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

    expect_locate 'santiago de chile', -33.42536, -70.566466, 'Santiago, Chile'
    expect_shorten_google_maps 'Santiago, Chile', 'http://short.url'

    send_message 1, "@Group1 at santiago de chile"

    assert_messages_sent_to 1, T.location_successfuly_updated('Santiago, Chile', 'lat: -33.42536, lon: -70.566466, url: http://short.url')
    assert_messages_sent_to 2..4, "User1: #{T.at_place 'Santiago, Chile', 'lat: -33.42536, lon: -70.566466, url: http://short.url'}"
    assert_message_saved "User1", "Group1", "at santiago de chile"
  end

  test "send message to group that does not exist" do
    create_users 1

    send_message 1, "@GroupTwo Hello!"
    assert_messages_sent_to 1, T.group_does_not_exist('GroupTwo')
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
    assert_messages_sent_to 1, T.cant_send_messages_to_disabled_group('Group1')
    assert_no_messages_sent_to 2
  end

  test "send message to disabled group" do
    create_users 1, 2
    create_group 1, "Group1"
    send_message 2, "join Group1"

    disable_group "Group1"
    send_message 1, "hello"
    assert_messages_sent_to 1, T.cant_send_messages_to_disabled_group('Group1')
    assert_no_messages_sent_to 2
  end

  test "send message prefixed with admin invited group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 2, "invite 1"

    send_message 1, "Group2 Hello"
    assert_messages_sent_to 1, T.welcome_to_group('User1', 'Group2', 2)
    assert_messages_sent_to 2, "User1: Hello"
    assert_group_exists "Group2", "User1", "User2"
    assert_no_invite_exists
  end

  test "send message prefixed with non-admin invited public group (first group)" do
    create_users 1, 2
    create_group 1, "Group1"
    send_message 1, "invite 2"

    send_message 2, "Group1 Hello"
    assert_messages_sent_to 2, T.welcome_to_group('User2', 'Group1')
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
    assert_messages_sent_to 1, T.welcome_to_group('User1', 'Group2', 2)
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
    assert_messages_sent_to 1, T.cant_send_message_to_group_invitation_not_approved('Group2')
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
    assert_messages_sent_to 1, T.cant_send_message_to_group_not_a_member('Group2')
    assert_no_messages_sent_to 2
  end

  test "send message targeted to invisible public group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 1, "@Group2 Hello!"
    assert_messages_sent_to 1, T.welcome_to_group('User1', 'Group2', 2)
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
    assert_messages_sent_to 2, T.message_only_to_you('User1', [], "Hello!")
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
      assert_messages_sent_to 2, "[Group2] #{T.message_only_to_you 'User1', [], 'Hello!'}"
      assert_no_messages_sent_to 1, 3, 4
      assert_message_saved "User1", "Group2", "Hello!"
    end
  end

  test "send message to user fails no common group" do
    create_users 1, 2
    create_group 1, "Group1"
    create_group 2, "Group2"

    send_message 1, "@User2 Hello!"
    assert_messages_sent_to 1, T.cant_send_message_to_user_no_common_group('User2')
    assert_no_messages_sent_to 2
    assert_no_messages_saved
  end

  test "send message to user fails explicit group" do
    create_users 1..4
    create_group 1, "Group1"
    create_group 1, "Group2"

    send_message 2, "join Group1"
    send_message 3..4, "join Group1"
    send_message 3..4, "join Group2"

    send_message 1, "Group2 @User2 Hello!"
    assert_messages_sent_to 1, T.cant_send_message_to_user_via_group_does_not_belong('User2', 'Group2')
    assert_no_messages_sent_to 2, 3, 4
    assert_no_messages_saved
  end

  test "send message to many users" do
    create_users 1..4
    create_group 1, "Group1"
    send_message 2..4, "join Group1"

    send_message 1, "@User2 @User3 Hello!"
    assert_messages_sent_to 2, T.message_only_to_you('User1', ['User3'], 'Hello!')
  end

  test "send message to many users explicit group" do
    create_users 1..4
    create_group 1, "Group1"
    create_group 1, "Group2"
    send_message 2..4, "join Group1"
    send_message 2..4, "join Group2"

    send_message 1, "Group2 @User2 @User3 Hello!"
    assert_messages_sent_to 2, "[Group2] #{T.message_only_to_you('User1', ['User3'], 'Hello!')}"
  end

  test "send message to many users user not found" do
    create_users 1..4
    create_group 1, "Group1"
    create_group 1, "Group2"
    send_message 2..4, "join Group1"
    send_message 2..4, "join Group2"

    send_message 1, "Group2 @User2 @User5 Hello!"
    assert_messages_sent_to 1, T.user_does_not_exist('User5')
    assert_messages_sent_to 2, "[Group2] #{T.message_only_to_you('User1', [], 'Hello!')}"
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
    assert_messages_sent_to 1, T.message_only_to_user('User2', 'User3', 'Hello!')
    assert_messages_sent_to 3, T.message_only_to_you('User2', [], 'Hello!')
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
    assert_messages_sent_to 1, T.message_only_to_user('User2', 'User4', 'Hello!')
    assert_messages_sent_to 4, T.message_only_to_you('User2', [], 'Hello!')
    assert_message_saved "User2", "Group1", "Hello!"
  end

  test "send message does not belong to group" do
    create_users 1
    send_message 1, "Hello!"
    assert_messages_sent_to 1, T.you_dont_belong_to_any_group_yet
  end

  test "send message no default group" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "create Group2"

    send_message 1, "Hello!"
    assert_messages_sent_to 1, T.you_dont_have_a_default_group_prefix_messages
  end

  test "send message not logged in" do
    send_message 1, "Hello"
    assert_not_logged_in_message_sent_to 1
  end

end

