# coding: utf-8

require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  include Mocha::API

  setup do
    @pipeline = Pipeline.new
    PasswordGenerator.stubs(:new_password => 'MockPassword')
  end

  def send_message(address, message)
    address = "sms://#{address}" if address.is_a?(Integer)
    @pipeline.process address, message
  end

  def assert_user_doesnt_exist(login)
    assert_nil User.find_by_login(login), "Expected user #{login} not to exist"
  end

  def assert_user_exists(login)
    assert_not_nil User.find_by_login(login), "Expected user #{login} to exist"
  end

  def assert_user_is_logged_in(address, login, display_name = nil)
    address = "sms://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_not_nil channel, "Expected channel with address #{address} to exist"
    assert_equal :on, channel.status

    user = channel.user
    assert_equal login, user.login
    assert_equal display_name, user.display_name if display_name
  end

  def assert_user_is_logged_off(address, login, display_name = nil)
    address = "sms://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_not_nil channel, "Expected channel with address #{address} to exist"
    assert_equal :off, channel.status

    user = channel.user
    assert_equal login, user.login
    assert_equal display_name, user.display_name if display_name
  end

  def assert_channel_does_not_exist(address)
    address = "sms://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_nil channel, "Expected channel with address #{address} not to exist"
  end

  def assert_messages_sent_to(address, msgs)
    address = "sms://#{address}" if address.is_a?(Integer)
    actual = @pipeline.messages[address]
    msgs = *msgs
    assert_equal msgs, actual
  end

  def assert_no_messages_sent
    assert @pipeline.messages.empty?, "Expected no messages sent but there are these messages: #{@pipeline.messages}"
  end

  def assert_group_exists(group_alias, *users)
    group = Group.find_by_alias group_alias
    assert_not_nil "Expected group with alias #{group_alias} to exist"

    assert_equal users.sort, group.users.map(&:login).sort
  end

  def assert_not_logged_in_message_sent_to(user)
    assert_messages_sent_to user, 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def assert_invite_exists(group, *users)
    users.each do |user|
      invite = Invite.joins(:group).joins(:user).where('groups.alias = ? AND users.login = ?', group, user).first
      assert_not_nil invite, "Expected invite to #{user} in group #{group} to exist"
    end
  end

  def create_users(*args)
    args.each do |num|
      send_message "sms://#{num}", ".name User#{num}"
    end
  end

  def create_group(user, group)
    send_message user, "create group #{group}"
  end
end
