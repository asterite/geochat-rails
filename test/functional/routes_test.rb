require 'test_helper'

class RoutesTest < ActionController::TestCase
  test "nuntium receive at" do
    assert_routing({:path => '/nuntium/receive_at', :method => :get}, {:controller => 'nuntium', :action => 'receive_at'})
  end

  test "api create user" do
    assert_routing({:path => '/api/users/create/foo', :method => :post}, {:controller => 'api', :action => 'create_user', :login => 'foo'})
  end
end
