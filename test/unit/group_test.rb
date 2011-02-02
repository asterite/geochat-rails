require 'test_helper'

class GroupTest < ActiveSupport::TestCase
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
      :requireApprovalToJoin => group.requires_aproval_to_join,
      :isChatRoom => group.chatroom?,
      :created => group.created_at,
      :updated => group.updated_at,
    }.to_json, group.to_json)
  end
end
