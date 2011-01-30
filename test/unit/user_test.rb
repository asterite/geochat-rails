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
end
