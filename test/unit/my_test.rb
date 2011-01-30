# coding: utf-8

require 'unit/pipeline_test'

class MyTest < PipelineTest
  test "get my login" do
    send_message 1, ".name John Doe"
    send_message 1, "#my login"

    assert_messages_sent_to 1, "Your login is: JohnDoe"
  end

  test "set my login" do
    send_message 1, ".name John Doe"
    send_message 1, "#my login FooBar"

    assert_messages_sent_to 1, "Your can't change your login"
  end

  test "get my name" do
    send_message 1, ".name John Doe"
    send_message 1, "#my name"

    assert_messages_sent_to 1, "Your display name is: John Doe"
  end

  test "set my name" do
    send_message 1, ".name John Doe"
    send_message 1, "#my name Foo Bar"

    assert_messages_sent_to 1, "Your new display name is: Foo Bar"
    assert_equal 'Foo Bar', User.find_by_login("JohnDoe").display_name
  end

  test "get my groups no groups" do
    send_message 1, ".name John Doe"
    send_message 1, "#my groups"

    assert_messages_sent_to 1, "You don't belong to any group yet. To join a group send: join groupalias"
  end

  test "get my groups one" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group2"

    send_message 1, "#my groups"
    assert_messages_sent_to 1, "Your only group is: Group2"
  end

  test "get my groups many" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group2"
    send_message 1, "create Group1"

    send_message 1, "#my groups"
    assert_messages_sent_to 1, "Your groups are: Group1, Group2"
  end

  test "get my group no groups" do
    send_message 1, ".name John Doe"
    send_message 1, "#my group"

    assert_messages_sent_to 1, "You don't belong to any group yet. To join a group send: join groupalias"
  end

  test "get my group single group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "#my group"

    assert_messages_sent_to 1, "Your default group is: Group1"
  end

  test "get my group no default group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "#my group"

    assert_messages_sent_to 1, "Your don't have a default group. To choose one send: #my group groupalias"
  end

  test "get my group other group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "#my group Group2"
    send_message 1, "#my group"

    assert_messages_sent_to 1, "Your default group is: Group2"
  end

  test "set my group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "#my group Group2"
    assert_messages_sent_to 1, "Your new default group is: Group2"
  end

  test "set my group does not exist" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, "#my group Group3"
    assert_messages_sent_to 1, "The group Group3 does not exist."
  end

  test "set my group does not belong to" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "create Group2"

    send_message 1, "#my group Group2"
    assert_messages_sent_to 1, "You can't set Group2 as your default group because you don't belong to it."
  end

  test "get my password" do
    create_users 1

    send_message 1, "#my password"
    assert_messages_sent_to 1, "Forgot your password? Set it via: #my password newpassword"
  end

  test "set my password" do
    create_users 1

    send_message 1, "#my password foobar"
    assert_messages_sent_to 1, "Your new password is: foobar"

    send_message 1, "logout"
    send_message 1, "login User1 foobar"
    assert_user_is_logged_in 1, "User1"
  end

  test "get my number" do
    create_users 1

    send_message 1, "#my number"
    assert_messages_sent_to 1, "Your phone number is: 1"
  end

  test "set my number" do
    create_users 1

    send_message 1, "#my number 1234"
    assert_messages_sent_to 1, "You can't change your phone number."
  end

  test "get my location never reported" do
    create_users 1

    send_message 1, "#my location"
    assert_messages_sent_to 1, "You never reported your location."
  end

  test "get my location" do
    create_users 1

    Geocoder.expects(:locate).with('Paris').returns([10.2, 30.4])
    Geocoder.expects(:reverse).with([10.2, 30.4]).returns("Paris, France")
    send_message 1, "at Paris"
    send_message 1, "#my location"
    assert_messages_sent_to 1, "You said you was in Paris, France (lat: 10.2, lon: 30.4) less than a minute ago."
  end

  test "set my location with place" do
    create_users 1

    Geocoder.expects(:locate).with('Paris').returns([10.2, 30.4])
    Geocoder.expects(:reverse).with([10.2, 30.4]).returns("Paris, France")
    send_message 1, "#my location Paris"
    assert_messages_sent_to 1, "Your location was successfully updated to Paris, France (lat: 10.2, lon: 30.4)"
    assert_user_location "User1", "Paris, France", 10.2, 30.4
  end

  test "set my location with coords" do
    create_users 1

    Geocoder.expects(:reverse).with([10.2, 30.4]).returns('Paris')
    send_message 1, "#my location 10.2, 30.4"
    assert_messages_sent_to 1, "Your location was successfully updated to Paris (lat: 10.2, lon: 30.4)"
    assert_user_location "User1", "Paris", 10.2, 30.4
  end
end
