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
    assert_user_is_logged_in 1, "User1"
    assert_messages_sent_to 1, "You sent '#on' and we have turned on SMS mobile updates to this phone. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  test "turn on implicitly when sending a message" do
    # TODO
  end
end
