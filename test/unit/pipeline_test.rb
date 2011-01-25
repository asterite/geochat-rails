# coding: utf-8

require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  include Mocha::API

  setup do
    @pipeline = Pipeline.new
    PasswordGenerator.stubs(:new_password => 'MockPassword')
  end

  def send_message(address, message)
    @pipeline.process address, message
  end

  def assert_user_doesnt_exist(login)
    assert_nil User.find_by_login(login), "Expected user #{login} to not exist"
  end

  def assert_user_exists(login)
    assert_not_nil User.find_by_login(login), "Expectes user #{login} to exist"
  end

  def assert_user_is_logged_in(address, login, display_name = nil)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_not_nil channel, "Channel for address #{address} not found"

    user = channel.user
    assert_equal login, user.login
    assert_equal display_name, user.display_name if display_name
  end

  def assert_channel_does_not_exist(address)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_nil channel, "Channel for address #{address} expected not to be found"
  end

  def assert_messages_sent_to(address, msgs)
    actual = @pipeline.messages[address]
    msgs = *msgs
    assert_equal msgs, actual
  end
end
