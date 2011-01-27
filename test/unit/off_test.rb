# coding: utf-8

require 'unit/pipeline_test'

class OffTest < PipelineTest
  test "turn off" do
    create_users 1

    send_message 1, "#off"

    assert_user_is_logged_off "sms://1", "User1"
    assert_messages_sent_to 1, "GeoChat Alerts. You sent '#off' and we have turned off SMS updates to this phone. Reply with START to turn back on. Questions email support@instedd.org."
  end

  test "turn off with stop" do
    create_users 1

    send_message 1, "stop"

    assert_user_is_logged_off "sms://1", "User1"
    assert_messages_sent_to 1, "GeoChat Alerts. You sent 'stop' and we have turned off SMS updates to this phone. Reply with START to turn back on. Questions email support@instedd.org."
  end

  test "turn off when off" do
    create_users 1

    send_message 1, "#off"
    send_message 1, "#off"

    assert_user_is_logged_off "sms://1", "User1"
    assert_no_messages_sent
  end

  test "off not logged in" do
    send_message 1, "off"
    assert_not_logged_in_message_sent_to 1
  end
end
