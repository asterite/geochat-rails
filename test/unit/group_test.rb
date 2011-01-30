require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  test "saves alias downcase" do
    group = Group.make :alias => 'HELLO'
    assert_equal 'hello', group.alias_downcase
  end

  test "find by alias case insensitive" do
    group = Group.make :alias => 'HELLO'
    assert_equal group, Group.find_by_alias("Hello")
  end
end
