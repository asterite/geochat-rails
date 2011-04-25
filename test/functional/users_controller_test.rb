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

  test "change location" do
    expect_reverse 11.558831, 104.91744500000004, 'Phnom Penh'
    expect_shorten_google_maps 11.558831, 104.91744500000004, 'http://short.url'

    post :update_location, :user => {:lat => 11.558831, :lon => 104.91744500000004}

    @user.reload

    assert_in_delta 11.558831, @user.lat, 1e-07
    assert_in_delta 104.91744500000004, @user.lon, 1e-07
    assert_equal 'Phnom Penh', @user.location
    assert_equal 'http://short.url', @user.location_short_url
  end
end
