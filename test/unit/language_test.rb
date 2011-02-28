# coding: utf-8

require 'unit/node_test'

class LanguageTest < NodeTest
  test "change language" do
    create_users 1

    assert_user_language 'User1', :en

    send_message 1, 'lang es'
    I18n.with_locale :es do
      assert_messages_sent_to 1, T.language_changed(I18n.locale_name :es)
    end
    assert_user_language 'User1', :es
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

  def assert_user_language(user, language)
    assert_equal language, User.find_by_login(user).language
  end
end
