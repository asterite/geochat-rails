# coding: utf-8

require 'unit/node_test'

class LanguageTest < NodeTest
  test "change language" do
    create_users 1

    assert_user_locale 'User1', :en

    send_message 1, 'lang es'
    I18n.with_locale :es do
      assert_messages_sent_to 1, T.language_changed(I18n.locale_name :es)
    end
    assert_user_locale 'User1', :es
  end

  test "change language not logged in" do
    send_message 1, 'lang es'
    assert_not_logged_in_message_sent_to 1
  end

  test "change language not found" do
    create_users 1

    send_message 1, "lang pirate"
    assert_messages_sent_to 1, T.geochat_is_not_available_in_language('pirate')
  end

  test "change language persists in other messages" do
    create_users 1
    send_message 1, "lang es"
    send_message 1, ".whereis User1"
    I18n.with_locale :es do
      assert_messages_sent_to 1, T.user_never_reported_location('User1')
    end
  end

  test "change language and send message to others" do
    create_users 1, 2
    send_message 2, "lang es"
    send_message 1, "create Group1"
    send_message 1, "invite User2"
    I18n.with_locale :es do
      assert_messages_sent_to 2, T.user_has_invited_you('User1', 'Group1')
    end
    assert_messages_sent_to 1, T.invitations_sent_to_users('User2')
  end

  test "change language send location report to others" do
    create_users 1, 2
    send_message 2, "lang es"
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    expect_locate 'Paris', 1, 2, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "at Paris"

    I18n.with_locale :es do
      assert_messages_sent_to 2, "User1: #{T.at_place 'Paris, France', 'lat: 1.0 N, lon: 2.0 E, url: http://short.url'}"
    end
  end

  def assert_user_locale(user, locale)
    assert_equal locale, User.find_by_login(user).locale
  end
end
