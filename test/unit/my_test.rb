# coding: utf-8

require 'unit/node_test'

class MyTest < NodeTest
  test "get my login" do
    send_message 1, ".name John Doe"
    send_message 1, ".my login"

    assert_messages_sent_to 1, T.your_login_is('JohnDoe')
  end

  test "set my login" do
    send_message 1, ".name John Doe"
    send_message 1, ".my login FooBar"

    assert_messages_sent_to 1, T.your_new_login_is('FooBar')
    assert_user_is_logged_in 1, "FooBar", "John Doe"
    assert_user_doesnt_exist "JohnDoe"
  end

  test "set my login already exists" do
    create_users 2
    send_message 1, ".name John Doe"
    send_message 1, ".my login User2"

    assert_messages_sent_to 1, T.login_taken('User2')
    assert_user_is_logged_in 1, "JohnDoe", "John Doe"
  end

  test "get my name" do
    send_message 1, ".name John Doe"
    send_message 1, ".my name"

    assert_messages_sent_to 1, T.your_display_name_is('John Doe')
  end

  test "set my name" do
    send_message 1, ".name John Doe"
    send_message 1, ".my name Foo Bar"

    assert_messages_sent_to 1, T.your_new_display_name_is('Foo Bar')
    assert_equal 'Foo Bar', User.find_by_login("JohnDoe").display_name
  end

  test "get my groups no groups" do
    send_message 1, ".name John Doe"
    send_message 1, ".my groups"

    assert_messages_sent_to 1, T.you_dont_belong_to_any_group_yet
  end

  test "get my groups one" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group2"

    send_message 1, ".my groups"
    assert_messages_sent_to 1, T.your_only_group_is('Group2')
  end

  test "get my groups many" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group2"
    send_message 1, "create Group1"

    send_message 1, ".my groups"
    assert_messages_sent_to 1, T.your_groups_are(['Group1', 'Group2'])
  end

  test "get my group no groups" do
    send_message 1, ".name John Doe"
    send_message 1, ".my group"

    assert_messages_sent_to 1, T.you_dont_belong_to_any_group_yet
  end

  test "get my group single group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, ".my group"

    assert_messages_sent_to 1, T.your_default_group_is('Group1')
  end

  test "get my group no default group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, ".my group"

    assert_messages_sent_to 1, T.you_dont_have_a_default_group_choose_one
  end

  test "get my group other group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, ".my group Group2"
    send_message 1, ".my group"

    assert_messages_sent_to 1, T.your_default_group_is('Group2')
  end

  test "set my group" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, ".my group Group2"
    assert_messages_sent_to 1, T.your_new_default_group_is('Group2')
  end

  test "set my group does not exist" do
    send_message 1, ".name John Doe"
    send_message 1, "create Group1"
    send_message 1, "create Group2"
    send_message 1, ".my group Group3"
    assert_messages_sent_to 1, T.group_does_not_exist('Group3')
  end

  test "set my group does not belong to" do
    create_users 1, 2
    send_message 1, "create Group1"
    send_message 2, "create Group2"

    send_message 1, ".my group Group2"
    assert_messages_sent_to 1, T.you_cant_set_group_as_default_group_dont_belong('Group2')
  end

  test "get my password" do
    create_users 1

    send_message 1, ".my password"
    assert_messages_sent_to 1, T.forgot_your_password?
  end

  test "set my password" do
    create_users 1

    send_message 1, ".my password foobar"
    assert_messages_sent_to 1, T.your_new_password_is('foobar')

    send_message 1, "logout"
    send_message 1, "login User1 foobar"
    assert_user_is_logged_in 1, "User1"
  end

  test "get my number" do
    create_users 1

    send_message 1, ".my number"
    assert_messages_sent_to 1, T.your_phone_number_is('1')
  end

  test "set my number" do
    create_users 1

    send_message 1, ".my number 1234"
    assert_messages_sent_to 1, T.you_cant_change_your_phone_number
  end

  test "get my email" do
    send_message "mailto://foo", ".name foo"

    send_message "mailto://foo", ".my email"
    assert_messages_sent_to "mailto://foo", T.your_email_is('foo')
  end

  test "set my email" do
    send_message "mailto://foo", ".name foo"

    send_message "mailto://foo", ".my email 1234"
    assert_messages_sent_to "mailto://foo", T.you_cant_change_your_email
  end

  test "get my location never reported" do
    create_users 1

    send_message 1, ".my location"
    assert_messages_sent_to 1, T.you_never_reported_your_location
  end

  test "get my location" do
    create_users 1

    expect_locate 'Paris', 10.2, 30.4, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "at Paris"
    send_message 1, ".my location"
    assert_messages_sent_to 1, T.you_said_you_was_in('Paris, France', "lat: 10.2, lon: 30.4, url: http://short.url", Time.now)
  end

  test "set my location with place" do
    create_users 1

    expect_locate 'Paris', 10.2, 30.4, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, ".my location Paris"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 10.2, lon: 30.4, url: http://short.url")
    assert_user_location "User1", "Paris, France", 10.2, 30.4, "http://short.url"
  end

  test "set my location with coords" do
    create_users 1

    expect_reverse 10.2, 30.4, 'Paris'
    expect_shorten_google_maps 10.2, 30.4, 'http://short.url'

    send_message 1, ".my location 10.2, 30.4"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris', "lat: 10.2, lon: 30.4, url: http://short.url")
    assert_user_location "User1", "Paris", 10.2, 30.4, "http://short.url"
  end

  test "my not logged in" do
    send_message 1, ".my login"
    assert_not_logged_in_message_sent_to 1
  end
end
