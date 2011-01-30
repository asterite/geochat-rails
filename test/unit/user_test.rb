require 'test_helper'

class UserTest < ActiveSupport::TestCase
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
    channel = Channel.make :user => user

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

  test "to json without location" do
    user = User.make

    assert_equal({
      :login => user.login,
      :displayName => user.display_name,
      :created => user.created_at,
      :updated => user.updated_at
      }.to_json, user.to_json)
  end

  test "to json with location" do
    user = User.make :lat => 10.2, :lon => 10.3, :location => 'Paris'

    assert_equal({
      :login => user.login,
      :displayName => user.display_name,
      :lat => user.lat,
      :long => user.lon,
      :location => user.location,
      :created => user.created_at,
      :updated => user.updated_at
      }.to_json, user.to_json)
  end
end
