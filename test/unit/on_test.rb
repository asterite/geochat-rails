# coding: utf-8

require 'unit/pipeline_test'

class OnTest < PipelineTest
  test "turn on" do
    create_users 1
    send_message 1, "#off"

    send_message 1, "#on"
    assert_user_is_logged_in 1, "User1"
    assert_messages_sent_to 1, "You sent '#on' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  test "turn on when on" do
    create_users 1

    send_message 1, "#on"
    assert_messages_sent_to 1, "You sent '#on' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
    assert_user_is_logged_in 1, "User1"
  end

  test "turn on with start" do
    create_users 1
    send_message 1, "#off"

    send_message 1, "start"
    assert_messages_sent_to 1, "You sent 'start' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
    assert_user_is_logged_in 1, "User1"
  end

  test "turn on implicitly when sending a message" do
    create_users 1
    send_message 1, "create Group1"
    send_message 1, "#off"

    send_message 1, "Hello!"
    assert_messages_sent_to 1, "We have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
    assert_user_is_logged_in 1, "User1"
  end

  test "on not logged in" do
    send_message 1, "on"
    assert_not_logged_in_message_sent_to 1
  end
end
