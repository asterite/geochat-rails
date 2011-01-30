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

  [['true', 'bar'], ['false', 'baz']].each do |value, pass|
    test "verify user credentials #{value}" do
      user = User.make :password => 'bar'
      get :verify_user_credentials, :login => user.login, :password => pass
      assert_response :ok
      assert_equal value, @response.body
    end
  end

  test "user groups not authorized" do
    user = User.make
    get :user_groups, :login => user.login
    assert_response :unauthorized
  end

  test "user groups" do
    user = User.make :password => 'foo'
    user.create_group :alias => 'one'
    user.create_group :alias => 'two'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user.login, 'foo')
    get :user_groups, :login => user.login
    assert_response :ok

    assert_equal user.groups.to_json, @response.body
  end

  test "group" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user.login, 'foo')
    get :group, :alias => group.alias
    assert_response :ok

    assert_equal group.to_json, @response.body
  end

  test "group unauthorized" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    get :group, :alias => group.alias
    assert_response :unauthorized
  end

  test "group unauthorized not member" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    user2 = User.make :password => 'bar'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user2.login, 'bar')
    get :group, :alias => group.alias
    assert_response :unauthorized
  end

  test "group members not authorized" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    get :group_members, :alias => group.alias
    assert_response :unauthorized
  end

  test "group members not found" do
    user = User.make :password => 'foo'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user.login, 'foo')
    get :group_members, :alias => 'bar'
    assert_response :not_found
  end

  test "group members not a member" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    user2 = User.make :password => 'bar'

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user2.login, 'bar')
    get :group_members, :alias => group.alias
    assert_response :unauthorized
  end

  test "group members" do
    user = User.make :password => 'foo'
    group = user.create_group :alias => 'one'

    user2 = User.make
    user2.join group

    @request.env['HTTP_AUTHORIZATION'] = http_auth(user.login, 'foo')
    get :group_members, :alias => group.alias
    assert_response :ok

    assert_equal(group.users.to_json, @response.body)
  end
end
