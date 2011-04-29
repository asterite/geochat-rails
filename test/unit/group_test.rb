require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test "doesn't allow short alias" do
    group = Group.make_unsaved :alias => 'a'
    assert !group.valid?
    assert_equal ['is too short (minimum is 3 characters)'], group.errors[:alias]
  end

  test "doesn't allow alias command" do
    group = Group.make_unsaved :alias => 'block'
    assert !group.valid?
    assert_equal ['is a reserved name'], group.errors[:alias]
  end

  test "doesn't allow spaces in alias" do
    group = Group.make_unsaved :alias => 'one two'
    assert !group.valid?
    assert_equal ["can only contain alphanumeric characters"], group.errors[:alias]
  end

  test "saves alias downcase" do
    group = Group.make :alias => 'HELLO'
    assert_equal 'hello', group.alias_downcase
  end

  test "find by alias case insensitive" do
    group = Group.make :alias => 'HELLO'
    assert_equal group, Group.find_by_alias("Hello")
  end

  test "destroys dependent memberships" do
    user = User.make
    group = Group.make
    user.join group

    group.destroy

    assert_equal 0, Membership.count
  end

  test "destroys dependent messages" do
    group = Group.make
    Message.make :group => group

    group.destroy

    assert_equal 0, Message.count
  end

  test "to json" do
    group = Group.make
    assert_equal({
      :alias => group.alias,
      :name => group.name,
      :isPublic => !group.hidden,
      :requireApprovalToJoin => group.requires_approval_to_join,
      :membersCount => group.users_count,
      :isChatRoom => group.chatroom?,
      :created => group.created_at,
      :updated => group.updated_at,
    }.to_json, group.to_json)
  end

  test "block user" do
    user = User.make
    group = Group.make
    user.join group
    group.block user

    group.reload

    assert user.is_blocked_in?(group)
    assert_equal 0, Membership.count
  end

  test "unblock user" do
    user = User.make
    group = Group.make
    group.block user
    group.unblock user

    group.reload

    assert !user.is_blocked_in?(group)
  end
end
