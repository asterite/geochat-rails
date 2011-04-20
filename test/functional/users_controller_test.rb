require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = login User.make(:password => 'secret')
  end

  test "change password" do
    post :update_password, :user => {:old_password => 'secret', :password => 'foo', :password_confirmation => 'foo'}

    @user.reload
    assert_not_nil @user.authenticate 'foo'

    assert_equal 'Your password was changed', flash[:notice]
    assert_redirected_to root_path
  end

  test "change password fails wrong old password" do
    post :update_password, :user => {:old_password => 'lala', :password => 'foo', :password_confirmation => 'foo'}

    @user.reload
    assert_not_nil @user.authenticate 'secret'
  end
end
