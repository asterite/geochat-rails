# coding: utf-8

require 'unit/pipeline_test'

class WhereIsTest < PipelineTest
  test "whois not a user" do
    create_users 1

    send_message 1, "#whois User2"
    assert_messages_sent_to 1, "The user User2 does not exist."
  end

  test "whois" do
    create_users 1, 2
    send_message 2, "#my name Foo Bar"

    send_message 1, "#whois User2"
    assert_messages_sent_to 1, "User2's display name is: Foo Bar."
  end
end
