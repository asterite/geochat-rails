# coding: utf-8

require 'test_helper'

class NodeTest < ActiveSupport::TestCase
  setup do
    PasswordGenerator.stubs(:new_password => 'MockPassword')
    @protocol = 'sms'
  end

  def send_message(address, message)
    Message.delete_all
    address = address.to_a if address.is_a?(Range)
    address = *address
    address.each do |a|
      a = "#{@protocol}://#{a}" if a.is_a?(Integer)
      @messages = Node.process :from => a, :to => 'geochat://system', :body => message
    end
  end

  def disable_group(group)
    group = Group.find_by_alias group
    group.enabled = false
    group.save!
  end

  def assert_user_doesnt_exist(login)
    assert_nil User.find_by_login(login), "Expected user #{login} not to exist"
  end

  def assert_user_exists(login)
    assert_not_nil User.find_by_login(login), "Expected user #{login} to exist"
  end

  def assert_user_is_logged_in(address, login, display_name = nil)
    address = "#{@protocol}://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_not_nil channel, "Expected channel with address #{address} to exist"
    assert_equal :on, channel.status

    user = channel.user
    assert_equal login, user.login
    assert_equal display_name, user.display_name if display_name
  end

  def assert_user_is_logged_off(address, login, display_name = nil)
    address = "#{@protocol}://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_not_nil channel, "Expected channel with address #{address} to exist"
    assert_equal :off, channel.status

    user = channel.user
    assert_equal login, user.login
    assert_equal display_name, user.display_name if display_name
  end

  def assert_channel_does_not_exist(address)
    address = "#{@protocol}://#{address}" if address.is_a?(Integer)
    protocol, address2 = address.split "://"
    channel = Channel.find_by_protocol_and_address protocol, address2
    assert_nil channel, "Expected channel with address #{address} not to exist"
  end

  def assert_messages_sent_to(address, msgs, options = {})
    address = address.to_a if address.is_a?(Range)
    address = *address
    address.each do |a|
      a = "#{@protocol}://#{a}" if a.is_a?(Integer)
      actual = @messages.select{|x| x[:to] == a}
      actual.each { |x| x.delete :from }
      msgs = *msgs
      i = -1
      expected = msgs.map{|x| i += 1; (options.is_a?(Array) ? options[i] : options).merge(:to => a, :body => x)}
      expected.each { |x| x.delete :from }
      assert_equal expected, actual, "Mismatched messages to #{a}"
    end
  end

  def assert_no_messages_sent_to(*address)
    address.each do |a|
      a = "#{@protocol}://#{a}" if a.is_a?(Integer)
      actual = @messages.select{|x| x[:to] == a}
      assert actual.empty?
    end
  end

  def assert_no_messages_sent
    assert @messages.empty?, "Expected no messages sent but there are these messages: #{@messages}"
  end

  def assert_no_messages_saved
    assert_equal 0, Message.count
  end

  def assert_is_not_group_admin(group, user)
    user = User.find_by_login(user)
    group = Group.find_by_alias group
    assert !user.is_admin_of?(group)
  end

  def assert_group_exists(group_alias, *users)
    group = Group.find_by_alias group_alias
    assert_not_nil "Expected group with alias #{group_alias} to exist"

    assert_equal users.sort, group.users.map(&:login).sort
  end

  def assert_group_admins(group_alias, *users)
    group = Group.find_by_alias group_alias
    actual = group.admins.map!(&:login)
    assert_equal users.sort, actual.sort
  end

  def assert_not_logged_in_message_sent_to(user)
    assert_messages_sent_to user, T.you_are_not_signed_in
  end

  def assert_invite_exists(group, *users)
    users.each do |user|
      invite = Invite.joins(:group).joins(:user).where('groups.alias = ? AND users.login = ?', group, user).first
      assert_not_nil invite, "Expected invite to #{user} in group #{group} to exist"
    end
  end

  def assert_no_invite_exists
    count = Invite.count
    assert_equal 0, count, "Expected no invite to exist but there exist #{count} invites: #{Invite.all}"
  end

  def assert_pending_approval(group, user)
    invite = Invite.joins(:group).joins(:user).where('groups.alias = ? AND users.login = ?', group, user).first
    assert invite.user_accepted
    assert !invite.admin_accepted
  end

  def assert_invite_suggestion_exists(group, user)
    invite = Invite.joins(:group).joins(:user).where('groups.alias = ? AND users.login = ?', group, user).first
    assert !invite.user_accepted
    assert !invite.admin_accepted
  end

  def assert_user_was_created_from_invite(user)
    user = User.find_by_login user
    assert user.created_from_invite, "Expected user #{user} to be created from invite"
  end

  def assert_user_was_not_created_from_invite(user)
    user = User.find_by_login user
    assert !user.created_from_invite, "Expected user #{user} not to be created from invite"
  end

  def assert_user_location(user, location, lat, lon, short_url)
    user = User.find_by_login user
    assert_in_delta lat, user.lat.to_f, 1e-07
    assert_in_delta lon, user.lon.to_f, 1e-07
    assert_equal location, user.location
    assert_equal short_url, user.location_short_url
  end

  def create_users(*args)
    args = args.first.to_a if args.first.is_a?(Range)
    args.each do |num|
      send_message "#{@protocol}://#{num}", ".name User#{num}"
    end
  end

  def create_group(user, group)
    send_message user, "create group #{group}"
  end

  def create_user_custom_location(user, name, lat, lon, full_address, short_url)
    expect_reverse lat, lon, full_address
    expect_shorten_google_maps lat, lon, short_url

    User.find_by_login(user).custom_locations.create! :name => name, :lat => lat, :lon => lon
  end

  def create_group_custom_location(group, name, lat, lon, full_address, short_url)
    expect_reverse lat, lon, full_address
    expect_shorten_google_maps lat, lon, short_url

    Group.find_by_alias(group).custom_locations.create! :name => name, :lat => lat, :lon => lon
  end

  def set_requires_approval_to_join(group)
    group = Group.find_by_alias group
    group.requires_approval_to_join = true
    group.save!
  end
end
