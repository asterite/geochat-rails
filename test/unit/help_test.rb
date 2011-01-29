# coding: utf-8

require 'unit/pipeline_test'

class HelpTest < PipelineTest
  test "help" do
    send_message 1, "help"
    assert_messages_sent_to 1, "GeoChat help center. Send help followed by a topic. Topics: signup, login, logout, create, join, leave, invite, on, off, my, whereis, whois, owner."
  end

  test "help signup" do
    send_message 1, "help signup"
    assert_messages_sent_to 1, "To signup in GeoChat send: name YOUR_NAME"
  end

  test "help login" do
    send_message 1, "help login"
    assert_messages_sent_to 1, "To login to GeoChat from this channel send: login YOUR_LOGIN YOUR_PASSWORD"
  end

  ["logout", "logoff"].each do |keyword|
    test "help #{keyword}" do
      send_message 1, "help #{keyword}"
      assert_messages_sent_to 1, "To logout from GeoChat send: logout"
    end
  end

  test "help create" do
    send_message 1, "help create"
    assert_messages_sent_to 1, "To create a group send: create GROUP_ALIAS"
  end

  test "help join" do
    send_message 1, "help join"
    assert_messages_sent_to 1, "To join a group send: join GROUP_ALIAS"
  end

  test "help leave" do
    send_message 1, "help leave"
    assert_messages_sent_to 1, "To leave a group send: leave GROUP_ALIAS"
  end

  test "help invite" do
    send_message 1, "help invite"
    assert_messages_sent_to 1, "To invite someone to a group send: GROUP_ALIAS +PHONE_NUMBER_OR_LOGIN"
  end

  test "help on" do
    send_message 1, "help on"
    assert_messages_sent_to 1, "To start receiving messages from this channel send: on"
  end

  test "help off" do
    send_message 1, "help off"
    assert_messages_sent_to 1, "To stop receiving messages from this channel send: off"
  end

  test "help my" do
    send_message 1, "help my"
    assert_messages_sent_to 1, "To change your settings send: #my OPTION or #my OPTION VALUE. Options: login, password, name, email, phone, location, group, groups"
  end

  test "help whereis" do
    send_message 1, "help whereis"
    assert_messages_sent_to 1, "To find out the location of a user send: #whereis USER_LOGIN"
  end

  test "help whois" do
    send_message 1, "help whois"
    assert_messages_sent_to 1, "To find out the display name of a user send: #whois USER_LOGIN"
  end

  test "help owner" do
    send_message 1, "help owner"
    assert_messages_sent_to 1, "To make a user owner of a group send: owner GROUP_ALIAS USER_LOGIN"
  end
end
