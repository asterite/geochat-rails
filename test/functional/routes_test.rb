require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "nuntium receive at" do
    assert_routing({:path => '/nuntium/receive_at', :method => :get}, {:controller => 'nuntium', :action => 'receive_at'})
  end

  test "api create user" do
    assert_routing({:path => '/api/users/create/foo', :method => :post}, {:controller => 'api', :action => 'create_user', :login => 'foo'})
  end

  test "api user" do
    assert_routing({:path => '/api/users/foo', :method => :get}, {:controller => 'api', :action => 'user', :login => 'foo'})
  end

  test "api verify user credentials" do
    assert_routing({:path => '/api/users/foo/verify', :method => :get}, {:controller => 'api', :action => 'verify_user_credentials', :login => 'foo'})
  end

  test "api user groups" do
    assert_routing({:path => '/api/users/foo/groups', :method => :get}, {:controller => 'api', :action => 'user_groups', :login => 'foo'})
  end
end
