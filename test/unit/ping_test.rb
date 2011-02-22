# coding: utf-8

require 'unit/pipeline_test'

class PingTest < PipelineTest
  test "ping" do
    send_message 1, 'ping'
    assert_messages_sent_to 1, "pong (#{T.received_at Time.now.utc})"
  end

  test "ping with message" do
    send_message 1, 'ping foo bar'
    assert_messages_sent_to 1, "pong: foo bar (#{T.received_at Time.now.utc})"
  end
end
