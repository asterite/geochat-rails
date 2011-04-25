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

    assert @user.is_owner_of?(groups[0])
    group_plan.each do |key, value|
      assert_equal value, groups[0].send(key)
    end
  end

  test "join group" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => false

    get :join, :id => 'bar'

    assert "You are now a member of #{group.alias}"
    assert_redirected_to group

    assert @user.belongs_to?(group)
  end

  test "can't join group that requires approval" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true

    get :join, :id => 'bar'

    assert "This group need approval to join"
    assert_redirected_to group

    assert !@user.belongs_to?(group)
  end

  test "join group when already joined" do
    group = @user.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => false

    get :join, :id => 'bar'

    assert "You already are a member of #{group.alias}"
    assert_redirected_to group
  end

  [:admin, :owner].each do |role|
    test "change role to #{role} if owner" do
      group = @user.create_group :alias => 'bar', :name => 'bar'
      user2 = User.make
      user2.join group
      get :change_role, :id => 'bar', :user => user2.login, :role => role

      user2.reload
      assert_equal role, user2.role_in(group)
    end
  end

  test "change role to admin if admin" do
    group = @user.create_group :alias => 'bar', :name => 'bar'

    user2 = login User.make
    user2.join group, :as => :admin

    user3 = User.make
    user3.join group

    get :change_role, :id => 'bar', :user => user3.login, :role => :admin

    user3.reload
    assert_equal :admin, user3.role_in(group)
  end

  test "change role to owner if admin fails" do
    group = @user.create_group :alias => 'bar', :name => 'bar'

    user2 = login User.make
    user2.join group, :as => :admin

    user3 = User.make
    user3.join group

    get :change_role, :id => 'bar', :user => user3.login, :role => :owner

    user3.reload
    assert_equal :member, user3.role_in(group)
  end

  test "change role of admin if admin fails" do
    group = @user.create_group :alias => 'bar', :name => 'bar'

    user2 = login User.make
    user2.join group, :as => :admin

    user3 = User.make
    user3.join group, :as => :admin

    get :change_role, :id => 'bar', :user => user3.login, :role => :member

    user3.reload
    assert_equal :admin, user3.role_in(group)
  end

  test "change role of admin if member fails" do
    group = @user.create_group :alias => 'bar', :name => 'bar'

    user2 = login User.make
    user2.join group

    user3 = User.make
    user3.join group, :as => :admin

    get :change_role, :id => 'bar', :user => user3.login, :role => :member

    user3.reload
    assert_equal :admin, user3.role_in(group)
  end
end
