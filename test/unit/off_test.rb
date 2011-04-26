# coding: utf-8

require 'unit/node_test'

class OffTest < NodeTest
  test "turn off" do
    create_users 1

    send_message 1, "off"

    assert_user_is_logged_off "sms://1", "User1"
    assert_messages_sent_to 1, T.you_sent_off_and_we_have_turned_off_channel('off', 'phone')
  end

  test "turn off with stop" do
    create_users 1

    send_message 1, "stop"

    assert_user_is_logged_off "sms://1", "User1"
    assert_messages_sent_to 1, T.you_sent_off_and_we_have_turned_off_channel('stop', 'phone')
  end

  test "turn off by email" do
    send_message 'mailto://foo@bar.com', '.name User1'
    send_message 'mailto://foo@bar.com', "off"

    assert_user_is_logged_off "mailto://foo@bar.com", "User1"
    assert_messages_sent_to 'mailto://foo@bar.com', T.you_sent_off_and_we_have_turned_off_channel('off', 'email')
  end

  test "turn off when off" do
    create_users 1

    send_message 1, "off"
    send_message 1, "off"

    assert_user_is_logged_off "sms://1", "User1"
    assert_no_messages_sent
  end

  test "off not logged in" do
    send_message 1, "off"
    assert_not_logged_in_message_sent_to 1
  end

  test "dont receive messages when off" do
    create_users 1, 2, 3
    send_message 1, "create Group1"
    send_message 2..3, "join Group1"
    send_message 2, "off"

    send_message 1, "Hello"
    assert_no_messages_sent_to 2
    assert_messages_sent_to 3, "User1: Hello", :group => 'Group1'
  end
end
