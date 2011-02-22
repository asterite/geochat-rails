# coding: utf-8

require 'unit/pipeline_test'

class HelpTest < PipelineTest
  test "help" do
    send_message 1, "help"
    assert_messages_sent_to 1, T.help_general
  end

  ['signup', 'login', 'logout', 'create', 'join', 'leave', 'invite', 'on', 'off', 'my', 'whereis', 'whois', 'owner'].each do |name|
    test "help #{name}" do
      send_message 1, "help #{name}"
      assert_messages_sent_to 1, T.send("help_#{name}")
    end
  end
end
