# coding: utf-8

require 'unit/pipeline_test'

class WhereIsTest < PipelineTest
  test "whereis not a user" do
    create_users 1

    send_message 1, "#whereis User2"
    assert_messages_sent_to 1, "The user User2 does not exist."
  end

  test "whereis not a visible user" do
    create_users 1, 2

    send_message 1, "#whereis User2"
    assert_messages_sent_to 1, "You can't see the location of User2 because you don't share a common group."
  end

  test "whereis answers unknown" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, "#whereis User2"
    assert_messages_sent_to 1, "User2 never reported his/her location."
  end

  test "whereis answers moments ago" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    Geocoder.expects(:reverse).with([10.2, 20.4]).returns("Paris")
    send_message 2, "at 10.2, 20.4"

    send_message 1, "#whereis User2"
    assert_messages_sent_to 1, "User2 said he/she was in Paris (lat: 10.2, lon: 20.4) less than a minute ago."
  end

  test "whereis answers time ago" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    now = Time.now
    Time.stubs :now => (now - 1.hour)

    Geocoder.expects(:reverse).with([10.2, 20.4]).returns("Paris")
    send_message 2, "at 10.2, 20.4"

    Time.stubs :now => now

    send_message 1, "#whereis User2"
    assert_messages_sent_to 1, "User2 said he/she was in Paris (lat: 10.2, lon: 20.4) about 1 hour ago."
  end

  test "whereis self" do
    create_users 1

    send_message 1, "#whereis User1"
    assert_messages_sent_to 1, "User1 never reported his/her location."
  end
end
