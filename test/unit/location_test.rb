# coding: utf-8

require 'unit/node_test'

class LocationTest < NodeTest
  test "place" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_locate 'Paris', 48.856667, 2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "at Paris"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
    assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'}"
    assert_user_location "User1", "Paris, France", 48.856667, 2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", "at Paris", "Paris, France", 48.856667, 2.350987, "http://short.url"
  end

  test "place with message" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_locate 'Paris', 48.856667, 2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "/Paris/ Hello!"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
    assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'})"
    assert_user_location "User1", "Paris, France", 48.856667, 2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", "Hello!", "Paris, France", 48.856667, 2.350987, "http://short.url"
  end

  ['at 48.856667 2.350987', 'at 48.856667, 2.350987'].each do |msg|
    test "lat/lon #{msg}" do
      create_users 1..4

      send_message 1, "create Group1"
      send_message 2..4, "join Group1"

      expect_reverse 48.856667, 2.350987, 'Paris'
      expect_shorten_google_maps 48.856667, 2.350987, 'http://short.url'

      send_message 1, msg
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'}"
      assert_user_location "User1", "Paris", 48.856667, 2.350987, "http://short.url"
      assert_message_saved_with_location "User1", "Group1", 'at 48.856667, 2.350987', "Paris", 48.856667, 2.350987, "http://short.url"
    end

    test "lat/lon with message #{msg}" do
      create_users 1..4

      send_message 1, "create Group1"
      send_message 2..4, "join Group1"

      expect_reverse 48.856667, 2.350987, 'Paris'
      expect_shorten_google_maps 48.856667, 2.350987, 'http://short.url'

      send_message 1, "#{msg} Hello!"
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'})"
      assert_user_location "User1", "Paris", 48.856667, 2.350987, "http://short.url"
      assert_message_saved_with_location "User1", "Group1", "Hello!", "Paris", 48.856667, 2.350987, "http://short.url"
    end

    test "lat/lon to group #{msg}" do
      create_users 1..4

      send_message 1, "create Group1"
      send_message 2..4, "join Group1"

      expect_reverse 48.856667, 2.350987, 'Paris'
      expect_shorten_google_maps 48.856667, 2.350987, 'http://short.url'

      send_message 1, "Group1 #{msg}"
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'}"
      assert_user_location "User1", "Paris", 48.856667, 2.350987, "http://short.url"
      assert_message_saved_with_location "User1", "Group1", 'at 48.856667, 2.350987', "Paris", 48.856667, 2.350987, "http://short.url"
    end

    test "lat/lon to group with message #{msg}" do
      create_users 1..4

      send_message 1, "create Group1"
      send_message 2..4, "join Group1"

      expect_reverse 48.856667, 2.350987, 'Paris'
      expect_shorten_google_maps 48.856667, 2.350987, 'http://short.url'

      send_message 1, "Group1 #{msg} Hello!"
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'})"
      assert_user_location "User1", "Paris", 48.856667, 2.350987, "http://short.url"
      assert_message_saved_with_location "User1", "Group1", "Hello!", "Paris", 48.856667, 2.350987, "http://short.url"
    end
  end

  test "place not found" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_locate_not_found 'Paris'

    send_message 1, "at Paris"
    assert_messages_sent_to 1, T.location_not_found('Paris')
    assert_messages_sent_to 2..4, "User1: at Paris"
    assert_user_location "User1", nil, 0, 0, nil
  end

  test "place not found with message" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_locate_not_found 'Paris'

    send_message 1, "at Paris * Hello"
    assert_messages_sent_to 1, T.location_not_found('Paris')
    assert_messages_sent_to 2..4, "User1: at Paris * Hello"
    assert_user_location "User1", nil, 0, 0, nil
  end

  test "lat/lon not found" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_reverse_not_found 10, 20

    send_message 1, "at 10, 20"
    assert_messages_sent_to 1, T.location_not_found('10.0, 20.0')
    assert_messages_sent_to 2..4, "User1: at 10, 20"
    assert_user_location "User1", nil, 0, 0, nil
  end

  test "preserve location in subsequent messages" do
    create_users 1
    send_message 1, "create Group1"

    expect_locate 'Paris', 48.856667, 2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "at Paris"
    send_message 1, "Hello"
    assert_message_saved_with_location "User1", "Group1", "Hello", "Paris, France", 48.856667, 2.350987, "http://short.url"
  end

  test "place with message too long to sms sends two messages" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    expect_locate 'Paris', -48.856667, 2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    without_message_length = "User1:  (#{T.at_place 'Paris, France', 'lat: 48.85667 S, lon: 2.35099 E, url: http://short.url'})".length
    gap_filler = "x" * (141 - without_message_length)

    send_message 1, "/Paris/ #{gap_filler}"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.85667 S, lon: 2.35099 E, url: http://short.url")
    assert_messages_sent_to 2..4, [
      "User1: #{T.at_place 'Paris, France', 'lat: 48.85667 S, lon: 2.35099 E, url: http://short.url'}",
      "User1: #{gap_filler}"
    ]
    assert_user_location "User1", "Paris, France", -48.856667, 2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", gap_filler, "Paris, France", -48.856667, 2.350987, "http://short.url"
  end

  test "place with message too long to email sends one message" do
    @protocol = 'mailto'

    1.upto 2 do |i|
      Node.process :from => "mailto://user#{i}@foo.com", :body => "name User#{i}"
    end

    send_message "mailto://user1@foo.com", "create Group1"
    send_message "mailto://user2@foo.com", "join Group1"

    expect_locate 'Paris', 48.856667, -2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    without_message_length = "User1:  (#{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 W, url: http://short.url'})".length
    gap_filler = "x" * (141 - without_message_length)

    send_message "mailto://user1@foo.com", "/Paris/ #{gap_filler}"
    assert_messages_sent_to "mailto://user1@foo.com", T.location_successfuly_updated('Paris, France', "lat: 48.85667 N, lon: 2.35099 W, url: http://short.url")
    assert_messages_sent_to "mailto://user2@foo.com", "User1: #{gap_filler} (#{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 W, url: http://short.url'})"
    assert_user_location "User1", "Paris, France", 48.856667, -2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", gap_filler, "Paris, France", 48.856667, -2.350987, "http://short.url"
  end

  test "user custom location" do
    create_users 1..2

    create_user_custom_location 1, 'custom', 48.856667, 2.350987, 'Paris, France', 'http://short.url'

    send_message 1, "create Group1"
    send_message 2, "join Group1"

    send_message 1, "at custom"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url")
    assert_messages_sent_to 2, "User1: #{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'}"
    assert_user_location "User1", "Paris, France", 48.856667, 2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", "at Paris, France", "Paris, France", 48.856667, 2.350987, "http://short.url"
  end

  # TODO USNG

  # TODO custom locations

end
