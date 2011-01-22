# coding: utf-8

require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def self.it_parses_node(string, clazz, options = {})
    test "parses #{clazz} #{string}" do
      node = Parser.parse(string)
      assert node.is_a?(clazz)
      options.each do |k, v|
        assert_equal v, node.send(k)
      end
    end
  end

  def self.it_parses_signup(string, options = {})
    test "parses signup #{string}" do
      node = Parser.parse(string)
      assert node.is_a?(SignupNode)
      assert_equal options[:display_name], node.display_name
      assert_equal options[:suggested_login] || options[:display_name], node.suggested_login
    end
  end

  def self.it_parses_login(string, options = {})
    it_parses_node string, LoginNode, options
  end

  def self.it_parses_logout(string)
    it_parses_node string, LogoutNode
  end

  def self.it_parses_on(string)
    it_parses_node string, OnNode
  end

  def self.it_parses_off(string)
    it_parses_node string, OffNode
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

  it_parses_logout "logout"
  it_parses_logout "lOgOuT"
  it_parses_logout "log out"
  it_parses_logout "bye"
  it_parses_logout ".logout"
  it_parses_logout ".log out"
  it_parses_logout ".bye"
  it_parses_logout ".lo"
  it_parses_logout "#logout"
  it_parses_logout "#log out"
  it_parses_logout "#bye"
  it_parses_logout "#lo"
  it_parses_logout ")"

  it_parses_on "on"
  it_parses_on "start"
  it_parses_on "sTaRt"
  it_parses_on ".on"
  it_parses_on ".start"
  it_parses_on "#on"
  it_parses_on "#start"
  it_parses_on "!"

  it_parses_off "off"
end
