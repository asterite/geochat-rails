require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup do
    @user = User.make :password => 'secret'
  end

  test "login with login" do
    get :create, :user => {:login => @user.login, :password => 'secret'}
    assert_equal @user.id, session[:user_id]
  end

  test "login with login is invalid" do
    get :create, :user => {:login => @user.login, :password => 'wrong'}
    assert_nil session[:user_id]
  end

  test "login with email" do
    @user.email_channels.create! :address => 'foo@bar.com', :status => :on

    get :create, :user => {:login => 'foo@bar.com', :password => 'secret'}
    assert_equal @user.id, session[:user_id]
  end

  test "activate email by registering" do
    Node.process :from => 'sms://1', :body => 'name User1'
    Node.process :from => 'sms://1', :body => 'create Group1'
    Node.process :from => 'sms://1', :body => 'invite foo@bar.com'

    group = Group.last
    invite = Invite.last

    get :activate_email, :id => invite.id, :email => 'foo@bar.com', :group => 'Group1'

    assert_redirected_to new_session_path
    assert_equal invite.id, session[:invite_id]

    get :register, :user => {:login => 'foo', :password => 'foo', :password_confirmation => 'foo'}

    assert_redirected_to group
    assert_equal "Welcome to GeoChat and to group Group1", flash.notice
    assert_nil session[:invite_id]

    assert_nil User.find_by_login 'foo@bar.com'

    user = User.find_by_login 'foo'
    assert user.belongs_to?(group)

    channels = user.channels
    assert_equal 1, channels.length
    assert_equal EmailChannel, channels[0].class
    assert_equal 'foo@bar.com', channels[0].address
    assert channels[0].on?

    assert_equal 3, User.count
    assert_equal 0, Invite.count
  end

  test "activate email by logging in" do
    Node.process :from => 'sms://1', :body => 'name User1'
    Node.process :from => 'sms://1', :body => 'create Group1'
    Node.process :from => 'sms://1', :body => 'invite foo@bar.com'

    user = User.make :login => 'foo', :password => 'foo'

    group = Group.last
    invite = Invite.last

    get :activate_email, :id => invite.id, :email => 'foo@bar.com', :group => 'Group1'

    assert_redirected_to new_session_path
    assert_equal invite.id, session[:invite_id]

    get :create, :user => {:login => 'foo', :password => 'foo'}

    assert_redirected_to group
    assert_equal "You are now a member of Group1", flash.notice
    assert_nil session[:invite_id]

    assert_nil User.find_by_login 'foo@bar.com'

    user = User.find_by_login 'foo'
    assert user.belongs_to?(group)

    channels = user.channels
    assert_equal 1, channels.length
    assert_equal EmailChannel, channels[0].class
    assert_equal 'foo@bar.com', channels[0].address
    assert channels[0].on?

    assert_equal 3, User.count
    assert_equal 0, Invite.count
  end

  test "activate email by logging in already belongs to group" do
    Node.process :from => 'sms://1', :body => 'name User1'
    Node.process :from => 'sms://1', :body => 'create Group1'
    Node.process :from => 'sms://1', :body => 'invite foo@bar.com'

    group = Group.last
    invite = Invite.last

    user = User.make :login => 'foo', :password => 'foo'
    user.join group

    get :activate_email, :id => invite.id, :email => 'foo@bar.com', :group => 'Group1'

    assert_redirected_to new_session_path
    assert_equal invite.id, session[:invite_id]

    get :create, :user => {:login => 'foo', :password => 'foo'}

    assert_redirected_to group
    assert_equal "You already are a member of Group1", flash.notice
    assert_nil session[:invite_id]

    assert_nil User.find_by_login 'foo@bar.com'

    user = User.find_by_login 'foo'
    assert user.belongs_to?(group)

    channels = user.channels
    assert_equal 1, channels.length
    assert_equal EmailChannel, channels[0].class
    assert_equal 'foo@bar.com', channels[0].address
    assert channels[0].on?

    assert_equal 3, User.count
    assert_equal 0, Invite.count
  end
end
