require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test "to json" do
    message = Message.make
    assert_equal({
      :id => message.id.to_s,
      :text => message.text,
      :group => message.group.alias,
      :sender => message.sender.login,
      :lat => message.lat.to_f,
      :long => message.lon.to_f,
      :location => message.location,
      :created => message.created_at,
    }.to_json, message.to_json)
  end
end
