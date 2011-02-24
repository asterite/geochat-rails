# coding: utf-8

require 'unit/node_test'

class HelpTest < NodeTest
  test "help" do
    send_message 1, "help"
    assert_messages_sent_to 1, T.help_help
  end

  ['signup', 'login', 'logout', 'create', 'join', 'leave', 'invite', 'on', 'off', 'my', 'owner'].each do |name|
    test "help #{name}" do
      send_message 1, "help #{name}"
      assert_messages_sent_to 1, T.send("help_#{name}")
    end
  end

  test "help whereis" do
    send_message 1, "help whereis"
    assert_messages_sent_to 1, T.help_where_is
  end

  test "help whois" do
    send_message 1, "help whois"
    assert_messages_sent_to 1, T.help_who_is
  end
end
