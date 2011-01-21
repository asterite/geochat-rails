# coding: utf-8

require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def self.it_parses_signup(string, options = {})
    test "parses signup #{string}" do
      node = Parser.parse(string)
      assert node.is_a?(SignupNode)
      assert_equal options[:display_name], node.display_name
      assert_equal options[:suggested_login] || options[:display_name], node.suggested_login
    end
  end

  it_parses_signup 'name DISPLAY NAME', :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
  it_parses_signup 'name @loginname', :display_name => 'loginname'
  it_parses_signup 'nAmE DISPLAY NAME', :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
  it_parses_signup '  name    DISPLAY NAME   ', :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
  it_parses_signup '#name @loginname', :display_name => 'loginname'
  it_parses_signup '.name @loginname', :display_name => 'loginname'
  it_parses_signup '. name @loginname', :display_name => 'loginname'
  it_parses_signup '.n @loginname', :display_name => 'loginname'
  it_parses_signup '#n @loginname', :display_name => 'loginname'
  it_parses_signup "'DISPLAY NAME'", :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
  it_parses_signup "'DISPLAY NAME", :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
  it_parses_signup "   '   DISPLAY NAME   '  ", :display_name => 'DISPLAY NAME', :suggested_login => 'DISPLAY_NAME'
end
