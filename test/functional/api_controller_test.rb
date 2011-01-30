require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "create user" do
    get :create_user, :login => 'foo', :password => 'bar', :displayname => 'Foo Bar'
    assert_response :ok

    users = User.all
    assert_equal 1, users.count

    user = users.first
    assert_equal 'foo', user.login
    assert_equal 'Foo Bar', user.display_name
    assert_equal user, User.authenticate('foo', 'bar')

    assert_equal user.to_json, @response.body
  end

  test "create user already exists" do
    user = User.make
    get :create_user, :login => user.login, :password => 'bar', :displayname => 'Foo Bar'
    assert_response :bad_request
  end

  test "user" do
    user = User.make
    get :user, :login => user.login
    assert_equal user.to_json, @response.body
  end

  test "user not found" do
    get :user, :login => 'foo'
    assert_response :not_found
  end
end
