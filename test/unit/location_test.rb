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
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.856667, lon: 2.350987, url: http://short.url")
    assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris, France', 'lat: 48.856667, lon: 2.350987, url: http://short.url'}"
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
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.856667, lon: 2.350987, url: http://short.url")
    assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris, France', 'lat: 48.856667, lon: 2.350987, url: http://short.url'})"
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
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.856667, lon: 2.350987, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris', 'lat: 48.856667, lon: 2.350987, url: http://short.url'}"
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
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.856667, lon: 2.350987, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris', 'lat: 48.856667, lon: 2.350987, url: http://short.url'})"
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
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.856667, lon: 2.350987, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: #{T.at_place 'Paris', 'lat: 48.856667, lon: 2.350987, url: http://short.url'}"
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
      assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 48.856667, lon: 2.350987, url: http://short.url")
      assert_messages_sent_to 2..4, "User1: Hello! (#{T.at_place 'Paris', 'lat: 48.856667, lon: 2.350987, url: http://short.url'})"
      assert_user_location "User1", "Paris", 48.856667, 2.350987, "http://short.url"
      assert_message_saved_with_location "User1", "Group1", "Hello!", "Paris", 48.856667, 2.350987, "http://short.url"
    end
  end

  test "place not found" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    Geocoder.expects(:locate).with('Paris').returns(nil)

    send_message 1, "at Paris"
    assert_messages_sent_to 1, T.location_not_found('Paris')
    assert_messages_sent_to 2..4, "User1: at Paris"
    assert_user_location "User1", nil, 0, 0, nil
  end

  test "place not found with message" do
    create_users 1..4

    send_message 1, "create Group1"
    send_message 2..4, "join Group1"

    Geocoder.expects(:locate).with('Paris').returns(nil)

    send_message 1, "at Paris * Hello"
    assert_messages_sent_to 1, T.location_not_found('Paris')
    assert_messages_sent_to 2..4, "User1: at Paris * Hello"
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

  # TODO USNG

  # TODO custom locations

end
