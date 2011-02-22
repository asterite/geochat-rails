# coding: utf-8

require 'unit/pipeline_test'

class WhereIsTest < PipelineTest
  test "whereis not a user" do
    create_users 1

    send_message 1, ".whereis User2"
    assert_messages_sent_to 1, T.user_does_not_exist('User2')
  end

  test "whereis not a visible user" do
    create_users 1, 2

    send_message 1, ".whereis User2"
    assert_messages_sent_to 1, T.you_cant_see_location_no_common_group('User2')
  end

  test "whereis answers unknown" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, ".whereis User2"
    assert_messages_sent_to 1, T.user_never_reported_location('User2')
  end

  test "whereis answers moments ago" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    expect_reverse 10.2, 20.4, 'Paris'
    expect_shorten_google_maps 10.2, 20.4, 'http://short.url'

    send_message 2, "at 10.2, 20.4"

    send_message 1, ".whereis User2"
    assert_messages_sent_to 1, T.user_said_she_was_in('User2', 'Paris', "lat: 10.2, lon: 20.4, url: http://short.url", Time.now.utc)
  end

  test "whereis self" do
    create_users 1

    send_message 1, ".whereis User1"
    assert_messages_sent_to 1, T.user_never_reported_location('User1')
  end

  test "whereis not signed in" do
    create_users 2
    send_message 1, ".whereis User2"
    assert_not_logged_in_message_sent_to 1
  end
end
