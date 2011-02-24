# coding: utf-8

require 'unit/node_test'

class WhereIsTest < NodeTest
  test "whois not a user" do
    create_users 1

    send_message 1, ".whois User2"
    assert_messages_sent_to 1, T.user_does_not_exist('User2')
  end

  test "whois" do
    create_users 1, 2
    send_message 2, ".my name Foo Bar"

    send_message 1, ".whois User2"
    assert_messages_sent_to 1, T.user_display_name_is(User.find_by_login('User2'))
  end

  test "whois not signed in" do
    create_users 2
    send_message 1, ".whois User2"
    assert_messages_sent_to 1, T.user_display_name_is(User.find_by_login('User2'))
  end
end
