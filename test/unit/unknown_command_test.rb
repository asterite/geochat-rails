# coding: utf-8

require 'unit/pipeline_test'

class UnknownCommandTest < PipelineTest
  test "it suggests my password" do
    send_message 1, ".my_passwor"
    assert_messages_sent_to 1, "Unknown command .my_passwor. Maybe you meant to send: .my password"
  end

  test "it suggests my password 2" do
    send_message 1, ".my_passwor something"
    assert_messages_sent_to 1, "Unknown command .my_passwor. Maybe you meant to send: .my password"
  end

  test "it suggests create" do
    send_message 1, ".creare"
    assert_messages_sent_to 1, "Unknown command .creare. Maybe you meant to send: .create"
  end

  test "it suggests create with dot" do
    send_message 1, ".creare"
    assert_messages_sent_to 1, "Unknown command .creare. Maybe you meant to send: .create"
  end
end

