# coding: utf-8

require 'unit/node_test'

class UnknownCommandTest < NodeTest
  test "it suggests my password" do
    send_message 1, ".my_passwor"
    assert_messages_sent_to 1, T.unknown_command('my_passwor', 'my password')
  end

  test "it suggests my password 2" do
    send_message 1, ".my_passwor something"
    assert_messages_sent_to 1, T.unknown_command('my_passwor', 'my password')
  end

  test "it suggests create" do
    send_message 1, ".creare"
    assert_messages_sent_to 1, T.unknown_command('creare', 'create')
  end
end

