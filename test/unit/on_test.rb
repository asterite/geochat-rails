# coding: utf-8

require 'unit/node_test'

class OnTest < NodeTest
  test "turn on" do
    create_users 1
    send_message 1, "off"

    send_message 1, "on"
    assert_user_is_logged_in 1, "User1"
    assert_messages_sent_to 1, T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel('on', 'phone')
  end

  test "turn on when on" do
    create_users 1

    send_message 1, "on"
    assert_user_is_logged_in 1, "User1"
    assert_messages_sent_to 1, T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel('on', 'phone')
  end

  test "turn on with start" do
    create_users 1
    send_message 1, "off"

    send_message 1, "start"
    assert_user_is_logged_in 1, "User1"
    assert_messages_sent_to 1, T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel('start', 'phone')
  end

  test "turn on implicitly when sending a message" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "off"

    send_message 1, "Hello!"
    assert_messages_sent_to 1, T.we_have_turned_on_updates_on_this_channel('phone')
    assert_user_is_logged_in 1, "User1"
  end

  test "on not logged in" do
    send_message 1, "on"
    assert_not_logged_in_message_sent_to 1
  end

  test "turn on by email" do
    send_message 'mailto://foo@bar.com', '.name User1'
    send_message 'mailto://foo@bar.com', "off"

    send_message 'mailto://foo@bar.com', "on"
    assert_user_is_logged_in 'mailto://foo@bar.com', "User1"
    assert_messages_sent_to 'mailto://foo@bar.com', T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel('on', 'email')
  end

  test "turn on implicitly when sending an email" do
    send_message 'mailto://foo@bar.com', '.name User1'
    send_message 'mailto://foo@bar.com', "create Group1"
    send_message 'mailto://foo@bar.com', "off"

    send_message 'mailto://foo@bar.com', "Hello!"
    assert_messages_sent_to 'mailto://foo@bar.com', T.we_have_turned_on_updates_on_this_channel('email')
    assert_user_is_logged_in 'mailto://foo@bar.com', "User1"
  end
end
