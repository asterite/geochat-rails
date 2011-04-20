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
end
