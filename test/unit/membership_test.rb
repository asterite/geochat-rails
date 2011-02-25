require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  test "increments user groups count on create" do
    user = User.make
    assert_equal 0, user.groups_count

    group = Group.make

    Membership.make :user => user, :group => group

    user.reload

    assert_equal 1, user.groups_count
  end

  test "decrement user groups count on destroy" do
    user = User.make
    group = Group.make

    membership = Membership.make :user => user, :group => group
    membership.destroy

    user.reload

    assert_equal 0, user.groups_count
  end

  test "remove user default group on destroy" do
    group = Group.make
    user = User.make :default_group_id => group.id

    membership = Membership.make :user => user, :group => group
    membership.destroy

    user.reload

    assert_nil user.default_group_id
  end
end
