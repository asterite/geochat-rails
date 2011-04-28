require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "doesn't allow short login" do
    user = User.make_unsaved :login => 'a'
    assert !user.valid?
    assert_equal ['is too short (minimum is 3 characters)'], user.errors[:login]
  end

  test "doesn't allow login command" do
    user = User.make_unsaved :login => 'block'
    assert !user.valid?
    assert_equal ['is a reserved name'], user.errors[:login]
  end

  test "doesn't allow spaces in login" do
    user = User.make_unsaved :login => 'one two'
    assert !user.valid?
    assert_equal ["can only contain alphanumeric characters"], user.errors[:login]
  end

  test "saves login downcase" do
    user = User.make :login => 'HELLO'
    assert_equal 'hello', user.login_downcase
  end

  test "find by login case insensitive" do
    user = User.make :login => 'HELLO'
    assert_equal user, User.find_by_login("Hello")
  end

  test "destroy dependent channels" do
    user = User.make
    channel = SmsChannel.make :user => user

    user.destroy

    assert_equal 0, Channel.count
  end

  test "destroy dependent memberships" do
    user = User.make
    group = Group.make
    user.join group

    user.destroy

    assert_equal 0, Membership.count
  end

  test "authenticate" do
    user = User.make :password => 'bar'
    assert_equal user, User.authenticate(user.login, 'bar')
  end

  test "authenticate fails" do
    user = User.make :password => 'bar'
    assert_nil User.authenticate(user.login, 'baz')
  end

  test "authenticate is backwards compatible" do
    User.connection.execute "INSERT INTO users (login, login_downcase, password) VALUES ('foo', 'foo', 'pStSHcCz+3lC2VIxqxS7jw==9ygzFIg1bJ4MxEMZkyYqTijrVWk=')"
    assert_not_nil User.authenticate 'foo', 'manzana'
  end

  test "requests" do
    u1 = User.make
    u2 = User.make
    u3 = User.make

    g1 = u1.create_group :name => 'foo', :alias => 'foo', :requires_approval_to_join => true
    g2 = u2.create_group :name => 'bar', :alias => 'bar', :requires_approval_to_join => true
    g3 = u3.create_group :name => 'baz', :alias => 'baz', :requires_approval_to_join => true

    request = u1.request_join g2
    other_request = u2.request_join g1
    invite = u1.invite u3, :to => g3

    assert_equal [request], u1.requests
    assert_equal [other_request], u1.others_requests
    assert_equal [invite], u1.invites
  end

  test "visible memberships of another user" do
    u1 = User.make
    u2 = User.make

    hidden_group = u2.create_group :name => 'hidden', :alias => 'hidden', :hidden => true
    public_group = u2.create_group :name => 'public', :alias => 'public', :hidden => false
    shared_group = u2.create_group :name => 'shared', :alias => 'shared', :hidden => true
    u1.join shared_group

    memberships = u1.visible_memberships_of u2
    assert_equal 2, memberships.length
    assert_equal [public_group.id, shared_group.id], memberships.sort{|x, y| x.group_id <=> y.group_id}.map(&:group_id)
  end

  test "to json" do
    user = User.make
    assert_equal({
      :login => user.login,
      :displayName => user.display_name,
      :lat => user.lat.to_f,
      :long => user.lon.to_f,
      :location => user.location,
      :created => user.created_at,
      :updated => user.updated_at
      }.to_json, user.to_json)
  end
end
