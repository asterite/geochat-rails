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

  test "join group deletes all invites to that group" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => false

    user2 = User.make
    user3 = User.make
  end

  test "join in group that requires approval" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true

    get :join, :id => 'bar'

    assert "Request to join group #{group} sent", flash[:notice]
    assert_redirected_to group
    assert !@user.belongs_to?(group)

    invites = Invite.all
    assert_equal 1, invites.length
    assert_equal @user.id, invites[0].user_id
    assert_equal group.id, invites[0].group_id
    assert invites[0].user_accepted?
    assert !invites[0].admin_accepted?
  end

  test "join in group that requires approval but already requested" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true
    @user.request_join group

    get :join, :id => 'bar'

    assert "You already requested to join #{group} sent", flash[:notice]
    assert_redirected_to group
    assert !@user.belongs_to?(group)
    assert_equal 1, Invite.count
  end

  test "join in group that requires approval and invited from other users" do
    group = User.make.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true

    other_user_1 = User.make
    other_user_1.join group

    other_user_2 = User.make
    other_user_2.join group

    other_user_1.invite @user, :to => group
    other_user_2.invite @user, :to => group

    get :join, :id => 'bar'

    assert "Request to join group #{group} sent", flash[:notice]
    assert_redirected_to group
    assert !@user.belongs_to?(group)

    invites = Invite.all
    assert_equal 2, invites.length
    assert invites.all?(&:user_accepted?)
    assert !invites.any?(&:admin_accepted?)

    get :join, :id => 'bar'

    assert "You already requested to join #{group}", flash[:notice]
  end

  test "join in group that requires approval and invited from other users and admin" do
    admin = User.make
    group = admin.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true

    other_user_1 = User.make
    other_user_1.join group

    other_user_2 = User.make
    other_user_2.join group

    other_user_1.invite @user, :to => group
    other_user_2.invite @user, :to => group
    admin.invite @user, :to => group

    get :join, :id => 'bar'

    assert "You are now a member of #{group}", flash[:notice]
    assert_redirected_to group
    assert @user.belongs_to?(group)
    assert_equal 0, Invite.count
  end

  test "join group when already joined" do
    group = @user.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => false

    get :join, :id => 'bar'

    assert "You already are a member of #{group.alias}"
    assert_redirected_to group
  end

  test "accept join request when requested to join" do
    group = @user.create_group :alias => 'bar', :name => 'bar', :requires_approval_to_join => true

    other_user = User.make
    other_user.request_join group

    user3 = User.make
    user3.join group
    user3.invite other_user, :to => group

    get :accept_join_request, :id => group.alias, :user => other_user.login

    assert_equal "You have accepted #{other_user.login} in #{group}", flash[:notice]
    assert_redirected_to invites_path
    assert other_user.belongs_to?(group)

    assert_equal 0, Invite.count
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

  test "change location" do
    group = @user.create_group :alias => 'bar', :name => 'bar'

    expect_reverse 11.558831, 104.91744500000004, 'Phnom Penh'

    post :update_location, :id => 'bar', :group => {:lat => 11.558831, :lon => 104.91744500000004}

    group.reload

    assert_in_delta 11.558831, group.lat, 1e-07
    assert_in_delta 104.91744500000004, group.lon, 1e-07
    assert_equal 'Phnom Penh', group.location
  end
end
