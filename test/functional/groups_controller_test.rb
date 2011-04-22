require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  setup do
    @user = login User.make
  end

  test "create group" do
    group_plan = Group.plan
    post :create, :group => group_plan

    assert "Group foo created"
    assert_redirected_to groups_path

    groups = Group.all
    assert_equal 1, groups.length

    assert @user.is_owner_of groups[0]
    group_plan.each do |key, value|
      assert_equal value, groups[0].send(key)
    end
  end
end
