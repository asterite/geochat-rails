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

  context 'with a user' do
    setup do
      @user = User.make :password => 'foo'
    end

    should "not be able to create user: already exists" do
      get :create_user, :login => @user.login, :password => 'bar', :displayname => 'Foo Bar'
      assert_response :bad_request
    end

    should "get user" do
      get :user, :login => @user.login
      assert_equal @user.to_json, @response.body
    end

    should "not found unexistent user" do
      get :user, :login => 'foo'
      assert_response :not_found
    end

    [['true', 'foo'], ['false', 'bar']].each do |value, pass|
      should "verify user credentials #{value}" do
        get :verify_user_credentials, :login => @user.login, :password => pass
        assert_response :ok
        assert_equal value, @response.body
      end
    end

    should "say unauthorized for user groups when not logged in" do
      get :user_groups, :login => @user.login
      assert_response :unauthorized
    end

    should "get user groups" do
      @user.create_group :alias => 'one', :name => 'one'
      @user.create_group :alias => 'two', :name => 'two'

      http_auth(@user.login, 'foo')
      get :user_groups, :login => @user.login
      assert_response :ok

      assert_equal @user.groups.to_json, @response.body
    end

    context 'in a group' do
      setup do
        @group = @user.create_group :alias => 'one', :name => 'one'
      end

      context 'not logged in' do
        should "say unauthorized for group" do
          get :group, :alias => @group.alias
          assert_response :unauthorized
        end

        should "say unauthorized for group members when not logged in" do
          get :group_members, :alias => @group.alias
          assert_response :unauthorized
        end
      end

      context 'logged in' do
        setup do
          http_auth(@user.login, 'foo')
        end

        should "get group" do
          get :group, :alias => @group.alias
          assert_response :ok

          assert_equal @group.to_json, @response.body
        end

        should "should not find group members for unexistent group" do
          get :group_members, :alias => 'bar'
          assert_response :not_found
        end

        should "get group members" do
          user2 = User.make
          user2.join @group

          get :group_members, :alias => @group.alias
          assert_response :ok

          assert_equal(@group.users.to_json, @response.body)
        end

        should "say not found for group messages when group does not exist" do
          get :group_messages, :alias => 'bar'
          assert_response :not_found
        end

        should "get group messages" do
          10.times { Message.make :group => @group, :sender => @user }

          get :group_messages, :alias => @group.alias, :page => '2', :per_page => '3'
          assert_response :ok

          assert_equal({
            :items => @group.messages.order('created_at DESC')[3 ... 6],
            :previousPage => "#{request.protocol}#{request.host_with_port}#{request.path}?page=1&per_page=3",
            :nextPage => "#{request.protocol}#{request.host_with_port}#{request.path}?page=3&per_page=3",
            }.to_json, @response.body)
        end
      end

      context 'logged in as another user' do
        setup do
          user2 = User.make :password => 'bar'
          http_auth(user2.login, 'bar')
        end

        should "say unauthorized for group when not member" do
          get :group, :alias => @group.alias
          assert_response :unauthorized
        end

        should "say unauthorized for group members when not a member" do
          get :group_members, :alias => @group.alias
          assert_response :unauthorized
        end

        should "say unauthorized for group messages when not a member" do
          get :group_messages, :alias => @group.alias
          assert_response :unauthorized
        end
      end
    end
  end
end
