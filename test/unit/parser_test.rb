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

  def self.it_parses_login(string, options = {})
    test "parses login #{string}" do
      node = Parser.parse(string)
      assert node.is_a?(LoginNode)
      assert_equal options[:login], node.login
      assert_equal options[:password], node.password
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

  it_parses_login "login username password", :login => 'username', :password => 'password'
  it_parses_login "LoGiN username password", :login => 'username', :password => 'password'
  it_parses_login "login 12345 password", :login => '12345', :password => 'password'
  it_parses_login "login 12345.6789 password", :login => '12345.6789', :password => 'password'
  it_parses_login "login @username password", :login => 'username', :password => 'password'
  it_parses_login "login @ username password", :login => 'username', :password => 'password'
  it_parses_login "log in username password", :login => 'username', :password => 'password'
  it_parses_login "iam username password", :login => 'username', :password => 'password'
  it_parses_login "i am username password", :login => 'username', :password => 'password'
  it_parses_login "i'm username password", :login => 'username', :password => 'password'
  it_parses_login "login +12345 +789", :login => '+12345', :password => '+789'
  it_parses_login ".im username password", :login => 'username', :password => 'password'
  it_parses_login ". im username password", :login => 'username', :password => 'password'
  it_parses_login ".i'm username password", :login => 'username', :password => 'password'
  it_parses_login ". i'm username password", :login => 'username', :password => 'password'
  it_parses_login ".iam username password", :login => 'username', :password => 'password'
  it_parses_login ". iam username password", :login => 'username', :password => 'password'
  it_parses_login ".li username password", :login => 'username', :password => 'password'
  it_parses_login "# iam username password", :login => 'username', :password => 'password'
  it_parses_login "...iam username password", :login => 'username', :password => 'password'
  it_parses_login "(username password", :login => 'username', :password => 'password'
  it_parses_login "( username password", :login => 'username', :password => 'password'
  it_parses_login "( @username password", :login => 'username', :password => 'password'
end
