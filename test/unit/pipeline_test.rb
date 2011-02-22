# coding: utf-8

require 'test_helper'

class PipelineTest < ActiveSupport::TestCase
  setup do
    @pipeline = Pipeline.new
    PasswordGenerator.stubs(:new_password => 'MockPassword')
  end

  def send_message(address, message)
    address = address.to_a if address.is_a?(Range)
    address = *address
    address.each do |a|
      a = "sms://#{a}" if a.is_a?(Integer)
      @pipeline.process :from => a, :body => message
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
    address = address.to_a if address.is_a?(Range)
    address = *address
    address.each do |a|
      a = "sms://#{a}" if a.is_a?(Integer)
      actual = @pipeline.messages.select{|x| x[:to] == a}
      msgs = *msgs
      expected = msgs.map{|x| {:to => a, :body => x}}
      assert_equal expected, actual, "Mismatched messages to #{a}"
    end
  end

  def assert_no_messages_sent_to(*address)
    address.each do |a|
      a = "sms://#{a}" if a.is_a?(Integer)
      actual = @pipeline.messages.select{|x| x[:to] == a}
      assert actual.empty?
    end
  end

  def assert_no_messages_sent
    assert @pipeline.messages.empty?, "Expected no messages sent but there are these messages: #{@pipeline.messages}"
  end

  def assert_no_messages_saved
    assert_nil @pipeline.saved_message
  end

  def assert_is_not_group_owner(group, user)
    user = User.find_by_login(user)
    group = Group.find_by_alias group
    assert !user.is_owner_of(group)
  end

  def assert_group_exists(group_alias, *users)
    group = Group.find_by_alias group_alias
    assert_not_nil "Expected group with alias #{group_alias} to exist"

    assert_equal users.sort, group.users.map(&:login).sort
  end

  def assert_group_owners(group_alias, *users)
    group = Group.find_by_alias group_alias
    actual = group.owners.map!(&:login)
    assert_equal users.sort, actual.sort
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

  def assert_message_saved(user, group, text)
    message = @pipeline.saved_message
    assert_not_nil message
    assert_equal user, message[:sender].login
    assert_equal group, message[:group].alias
    assert_equal text, message[:text]
    message
  end

  def assert_message_saved_with_location(user, group, text, location, lat, lon, short_url)
    message = assert_message_saved(user, group, text)
    assert_equal location, message[:location]
    assert_in_delta lat, message[:lat], 1e-07
    assert_in_delta lon, message[:lon], 1e-07
    assert_equal short_url, message[:location_short_url]
  end

  def create_users(*args)
    args = args.first.to_a if args.first.is_a?(Range)
    args.each do |num|
      send_message "sms://#{num}", ".name User#{num}"
    end
  end

  def create_group(user, group)
    send_message user, "create group #{group}"
  end

  def set_requires_aproval_to_join(group)
    group = Group.find_by_alias group
    group.requires_aproval_to_join = true
    group.save!
  end

  def set_forward_owners(group)
    group = Group.find_by_alias group
    group.forward_owners = true
    group.save!
  end

  def expect_locate(name, lat, lon, location)
    Geocoder.expects(:locate).with(name).returns({:lat => lat, :lon => lon, :location => location})
  end

  def expect_reverse(lat, lon, location)
    Geocoder.expects(:reverse).with([lat, lon]).returns(location)
  end

  def expect_shorten(long_url, short_url)
    Googl.expects(:shorten).with(long_url).returns(short_url)
  end

  def expect_shorten_google_maps(*params)
    if params.length == 3
      expect_shorten "http://maps.google.com/?q=#{params[0]},#{params[1]}", params[2]
    elsif params.length == 2
      expect_shorten "http://maps.google.com/?q=#{CGI.escape params[0]}", params[1]
    else
      raise "Expected 2 or 3 params for expect_shorten_google_maps"
    end
  end
end
