# coding: utf-8

require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def parse(string)
    lookup = stub('lookup', :is_group? => false)
    lookup.expects(:is_group?).with('MyGroup').returns(true)

    Parser.parse(string, lookup)
  end

  def self.it_parses_node(string, clazz, options = {})
    test "parses #{clazz} #{string}" do
      node = parse(string)
      assert node.is_a?(clazz), "expected to be #{clazz} but was #{node.class}"
      options.each do |k, expected|
        actual = node.send(k)
        assert_equal expected, actual, "expected #{k} to be #{expected} but was #{actual}"
      end
    end
  end

  def self.it_parses_signup(string, options = {})
    test "parses signup #{string}" do
      node = parse(string)
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

  def self.it_parses_create_group(string, options = {})
    it_parses_node string, CreateGroupNode, options
  end

  def self.it_parses_invite(string, options = {})
    it_parses_node string, InviteNode, options
  end

  def self.it_parses_join(string, options = {})
    it_parses_node string, JoinNode, options
  end

  def self.it_parses_leave(string, options = {})
    it_parses_node string, LeaveNode, options
  end

  def self.it_parses_block(string, options = {})
    it_parses_node string, BlockNode, options
  end

  def self.it_parses_owner(string, options = {})
    it_parses_node string, OwnerNode, options
  end

  def self.it_parses_message(string, options = {})
    test "parses message #{string}" do
      node = parse(string)
      assert node.is_a?(MessageNode), "expected to be messagenode but was #{node.class}"
      options[:locations] = [options[:location]] if options[:location]
      [:body, :targets, :locations, :mentions, :tags, :blast, :location].each do |k|
        expected = options[k]
        actual = node.send(k)
        assert_equal expected, actual, "expected #{k} to be #{expected} but was #{actual}"
      end
    end
  end

  def self.it_parses_help(string, options = {})
    it_parses_node string, HelpNode, options
  end

  def self.it_parses_my(string, options = {})
    it_parses_node string, MyNode, options
  end

  def self.it_parses_whois(string, options = {})
    it_parses_node string, WhoIsNode, options
  end

  def self.it_parses_whereis(string, options = {})
    it_parses_node string, WhereIsNode, options
  end

  def self.it_parses_language(string, options = {})
    it_parses_node string, LanguageNode, options
  end

  def self.location(*args)
    [deg(*args[0 .. 2]), deg(*args[3 .. 5])]
  end

  def self.deg(*args)
    if args[0] < 0
      -(-args[0] + args[1] / 60.0 + args[2] / 3600.0)
    else
      args[0] + args[1] / 60.0 + args[2] / 3600.0
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
  it_parses_off "ofF"
  it_parses_off "stop"
  it_parses_off ".off"
  it_parses_off ".stop"
  it_parses_off "#off"
  it_parses_off "#stop"
  it_parses_off "-"

  it_parses_create_group "create alias", :group => 'alias'
  it_parses_create_group "create 123alias", :group => '123alias'
  it_parses_create_group "creategroup alias", :group => 'alias'
  it_parses_create_group "create group alias", :group => 'alias'
  it_parses_create_group "create @alias", :group => 'alias'
  it_parses_create_group "create @ alias", :group => 'alias'
  it_parses_create_group "create alias nochat", :group => 'alias', :nochat => true
  it_parses_create_group "create alias alert", :group => 'alias', :nochat => true
  it_parses_create_group "create alias public", :group => 'alias', :public => true
  it_parses_create_group "create alias nohide", :group => 'alias', :public => true
  it_parses_create_group "create alias hide", :group => 'alias', :public => false
  it_parses_create_group "create alias private", :group => 'alias', :public => false
  it_parses_create_group "create alias visible", :group => 'alias', :public => true
  it_parses_create_group "create alias chat", :group => 'alias', :nochat => false
  it_parses_create_group "create alias chatroom", :group => 'alias', :nochat => false
  it_parses_create_group "create alias public nochat", :group => 'alias', :public => true, :nochat => true
  it_parses_create_group "create alias nochat public", :group => 'alias', :public => true, :nochat => true
  it_parses_create_group "create alias name foobar", :group => 'alias', :name => 'foobar'
  it_parses_create_group "create alias name foo bar baz", :group => 'alias', :name => 'foo bar baz'
  it_parses_create_group "create alias name foo bar baz public nochat", :group => 'alias', :name => 'foo bar baz', :public => true, :nochat => true
  it_parses_create_group "create alias public name foo bar baz nochat", :group => 'alias', :name => 'foo bar baz', :public => true, :nochat => true
  it_parses_create_group ".cg alias", :group => 'alias'
  it_parses_create_group "#cg alias", :group => 'alias'
  it_parses_create_group "*alias", :group => 'alias'
  it_parses_create_group "* alias", :group => 'alias'

  it_parses_invite "invite 0823242342", :users => ['0823242342']
  it_parses_invite "invite someone", :users => ['someone']
  it_parses_invite "invite 0823242342 group", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite +0823242342 group", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite 0823242342 @group", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite group 0823242342", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite @group 0823242342", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite group +0823242342", :users => ['0823242342'], :group => 'group'
  it_parses_invite "invite group +0823242342 +another user", :users => ['0823242342', 'another', 'user'], :group => 'group'
  it_parses_invite "invite +0823242342 +1234 +another user", :users => ['0823242342', '1234', 'another', 'user'], :group => nil
  it_parses_invite "invite someone group", :users => ['group'], :group => 'someone'
  it_parses_invite "invite someone @group", :users => ['group'], :group => 'someone'
  it_parses_invite "invite @group someone", :users => ['group'], :group => 'someone'
  it_parses_invite "@group invite someone", :users => ['someone'], :group => 'group'
  it_parses_invite "MyGroup invite someone", :users => ['someone'], :group => 'MyGroup'
  it_parses_invite "MyGroup invite +someone", :users => ['someone'], :group => 'MyGroup'
  it_parses_invite "MyGroup invite someone other", :users => ['someone', 'other'], :group => 'MyGroup'
  it_parses_invite "MyGroup invite +1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite "MyGroup invite 1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite ".invite 0823242342", :users => ['0823242342']
  it_parses_invite ".i 0823242342", :users => ['0823242342']
  it_parses_invite "#invite 0823242342", :users => ['0823242342']
  it_parses_invite "#i 0823242342", :users => ['0823242342']
  it_parses_invite "MyGroup .invite 1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite "MyGroup .i 1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite "MyGroup #invite 1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite "MyGroup #i 1234", :users => ['1234'], :group => 'MyGroup'
  it_parses_invite "+1234", :users => ['1234']
  it_parses_invite "+ 1234", :users => ['1234']
  it_parses_invite "+someone", :users => ['someone']
  it_parses_invite "+some one", :users => ['some', 'one']
  it_parses_invite "@group +1234", :users => ['1234'], :group => 'group'

  it_parses_join "join alias", :group => 'alias'
  it_parses_join "join @alias", :group => 'alias'
  it_parses_join "join group alias", :group => 'alias'
  it_parses_join "join group @alias", :group => 'alias'
  it_parses_join ".j @alias", :group => 'alias'
  it_parses_join ".join @alias", :group => 'alias'
  it_parses_join "#j @alias", :group => 'alias'
  it_parses_join "#join @alias", :group => 'alias'
  it_parses_join ">alias", :group => 'alias'
  it_parses_join ">@alias", :group => 'alias'
  it_parses_join "> alias", :group => 'alias'

  it_parses_leave "leave alias", :group => 'alias'
  it_parses_leave "leave @alias", :group => 'alias'
  it_parses_leave "leave group alias", :group => 'alias'
  it_parses_leave "leave group @alias", :group => 'alias'
  it_parses_leave ".l @alias", :group => 'alias'
  it_parses_leave ".leave @alias", :group => 'alias'
  it_parses_leave "#l @alias", :group => 'alias'
  it_parses_leave "#leave @alias", :group => 'alias'
  it_parses_leave "<alias", :group => 'alias'
  it_parses_leave "<@alias", :group => 'alias'
  it_parses_leave "< alias", :group => 'alias'

  it_parses_block "block someone", :user => 'someone'
  it_parses_block "block @someone", :user => 'someone'
  it_parses_block ".block someone", :user => 'someone'
  it_parses_block "#block someone", :user => 'someone'
  it_parses_block "block someone somegroup", :user => 'someone', :group => 'somegroup'
  it_parses_block "@somegroup block someone", :user => 'someone', :group => 'somegroup'
  it_parses_block "@somegroup #block someone", :user => 'someone', :group => 'somegroup'
  it_parses_block "@somegroup .block someone", :user => 'someone', :group => 'somegroup'
  it_parses_block "MyGroup block someone", :user => 'someone', :group => 'MyGroup'
  it_parses_block "MyGroup #block someone", :user => 'someone', :group => 'MyGroup'
  it_parses_block "MyGroup .block someone", :user => 'someone', :group => 'MyGroup'

  it_parses_owner "owner someone", :user => 'someone'
  it_parses_owner "owner @someone", :user => 'someone'
  it_parses_owner "owner someone somegroup", :user => 'someone', :group => 'somegroup'
  it_parses_owner "owner 123456 somegroup", :user => '123456', :group => 'somegroup'
  it_parses_owner "owner somegroup 123456", :user => '123456', :group => 'somegroup'
  it_parses_owner ".owner someone", :user => 'someone'
  it_parses_owner ".ow someone", :user => 'someone'
  it_parses_owner "#owner someone", :user => 'someone'
  it_parses_owner "#ow someone", :user => 'someone'
  it_parses_owner "@somegroup owner someone", :user => 'someone', :group => 'somegroup'
  it_parses_owner "@somegroup .ow someone", :user => 'someone', :group => 'somegroup'
  it_parses_owner "MyGroup owner someone", :user => 'someone', :group => 'MyGroup'
  it_parses_owner "MyGroup .ow someone", :user => 'someone', :group => 'MyGroup'
  it_parses_owner "$someone", :user => 'someone'
  it_parses_owner "$ someone", :user => 'someone'
  it_parses_owner "$someone somegroup", :user => 'someone', :group => 'somegroup'
  it_parses_owner "MyGroup $someone", :user => 'someone', :group => 'MyGroup'

  it_parses_my "#my groups", :key => MyNode::Groups, :value => nil
  it_parses_my ".my groups", :key => MyNode::Groups, :value => nil
  it_parses_my "#my group", :key => MyNode::Group, :value => nil
  it_parses_my ".my group", :key => MyNode::Group, :value => nil
  it_parses_my "#my g", :key => MyNode::Group, :value => nil
  it_parses_my ".my g", :key => MyNode::Group, :value => nil
  it_parses_my "#my group something", :key => MyNode::Group, :value => 'something'
  it_parses_my ".my group something", :key => MyNode::Group, :value => 'something'
  it_parses_my "#my g something", :key => MyNode::Group, :value => 'something'
  it_parses_my ".my g something", :key => MyNode::Group, :value => 'something'
  it_parses_my ".my g @something", :key => MyNode::Group, :value => 'something'
  it_parses_my "#my name", :key => MyNode::Name, :value => nil
  it_parses_my ".my name", :key => MyNode::Name, :value => nil
  it_parses_my "#my name something", :key => MyNode::Name, :value => 'something'
  it_parses_my ".my name something", :key => MyNode::Name, :value => 'something'
  it_parses_my ".my name something something", :key => MyNode::Name, :value => 'something something'
  it_parses_my "#my email", :key => MyNode::Email, :value => nil
  it_parses_my ".my email", :key => MyNode::Email, :value => nil
  it_parses_my "#my email something", :key => MyNode::Email, :value => 'something'
  it_parses_my ".my email something", :key => MyNode::Email, :value => 'something'
  it_parses_my "#my number", :key => MyNode::Number, :value => nil
  it_parses_my ".my number", :key => MyNode::Number, :value => nil
  it_parses_my "#my phone", :key => MyNode::Number, :value => nil
  it_parses_my ".my phone", :key => MyNode::Number, :value => nil
  it_parses_my "#my phonenumber", :key => MyNode::Number, :value => nil
  it_parses_my ".my phonenumber", :key => MyNode::Number, :value => nil
  it_parses_my "#my phone number", :key => MyNode::Number, :value => nil
  it_parses_my ".my phone number", :key => MyNode::Number, :value => nil
  it_parses_my "#my mobile", :key => MyNode::Number, :value => nil
  it_parses_my ".my mobile", :key => MyNode::Number, :value => nil
  it_parses_my "#my mobilenumber", :key => MyNode::Number, :value => nil
  it_parses_my ".my mobilenumber", :key => MyNode::Number, :value => nil
  it_parses_my "#my mobile number", :key => MyNode::Number, :value => nil
  it_parses_my ".my mobile number", :key => MyNode::Number, :value => nil
  it_parses_my "#my location", :key => MyNode::Location, :value => nil
  it_parses_my ".my location", :key => MyNode::Location, :value => nil
  it_parses_my "#my location something long", :key => MyNode::Location, :value => 'something long'
  it_parses_my ".my location something long", :key => MyNode::Location, :value => 'something long'
  it_parses_my "#my login", :key => MyNode::Login, :value => nil
  it_parses_my ".my login", :key => MyNode::Login, :value => nil
  it_parses_my "#my login something", :key => MyNode::Login, :value => 'something'
  it_parses_my ".my login something", :key => MyNode::Login, :value => 'something'
  it_parses_my "#my password", :key => MyNode::Password, :value => nil
  it_parses_my ".my password", :key => MyNode::Password, :value => nil
  it_parses_my "#my password something", :key => MyNode::Password, :value => 'something'
  it_parses_my ".my password something", :key => MyNode::Password, :value => 'something'
  # TODO set multiple things at once

  it_parses_whois "whois someuser", :user => 'someuser'
  it_parses_whois "whois @someuser", :user => 'someuser'
  it_parses_whois "whois someuser?", :user => 'someuser'
  it_parses_whois ".wi someuser", :user => 'someuser'
  it_parses_whois ".wi someuser?", :user => 'someuser'
  it_parses_whois "#wi someuser", :user => 'someuser'
  it_parses_whois "#wi someuser?", :user => 'someuser'

  it_parses_whereis "whereis someuser", :user => 'someuser'
  it_parses_whereis "whereis @someuser", :user => 'someuser'
  it_parses_whereis "whereis someuser?", :user => 'someuser'
  it_parses_whereis ".wh someuser", :user => 'someuser'
  it_parses_whereis ".wh someuser?", :user => 'someuser'
  it_parses_whereis "#wh someuser", :user => 'someuser'
  it_parses_whereis "#wh someuser?", :user => 'someuser'
  it_parses_whereis ".w someuser", :user => 'someuser'
  it_parses_whereis ".w someuser?", :user => 'someuser'

  it_parses_language "lang en", :name => 'en'
  it_parses_language ".lang en", :name => 'en'
  it_parses_language "#lang en", :name => 'en'
  it_parses_language "_en", :name => 'en'
  it_parses_language "_ en", :name => 'en'
  it_parses_language "___ en", :name => 'en'

  it_parses_message "@group 1234", :body => '1234', :targets => ['group']
  it_parses_message "1234", :body => '1234'
  it_parses_message "at bangkok", :location => "bangkok", :body => nil
  it_parses_message "at bangkok *", :location => "bangkok", :body => nil
  it_parses_message "l: bangkok", :location => "bangkok", :body => nil
  it_parses_message "l: bangkok *", :location => "bangkok", :body => nil
  it_parses_message "at", :body => 'at', :location => nil
  it_parses_message "l:", :body => 'l:', :location => nil
  it_parses_message "bangkok *", :location => "bangkok", :body => nil

  it_parses_message "30° 31' 32'' N * 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30 31' 32'' N * 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31 32'' N * 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32 N * 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' * 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N 33° 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33 34' 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33° 34 35'' E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33° 34' 35 E", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' N * 33° 34' 35'' E", :location => location(30, 31, 0, 33, 34, 35)
  it_parses_message "30° N * 33° 34' 35'' E", :location => location(30, 0, 0, 33, 34, 35)
  it_parses_message "30° * 33° 34' 35'' E", :location => location(30, 0, 0, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33° 34' E", :location => location(30, 31, 32, 33, 34, 0)
  it_parses_message "30° 31' 32'' N * 33° E", :location => location(30, 31, 32, 33, 0, 0)
  it_parses_message "30° 31' 32'' N * 33°", :location => location(30, 31, 32, 33, 0, 0)
  it_parses_message "30° 32'' N * 33° 34' 35'' E", :location => location(30, 0, 32, 33, 34, 35)
  #it_parses_message "30° 31' 32'' N * 33° 35'' E", :location => location(30, 31, 32, 33, 0, 35) # => currently fails
  it_parses_message "N 30° 31' 32'' * E 33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "-30° 31' 32'' * E 33° 34' 35''", :location => location(-30, 31, 32, 33, 34, 35)
  it_parses_message "- 30° 31' 32'' * E 33° 34' 35''", :location => location(-30, 31, 32, 33, 34, 35)
  it_parses_message "+30° 31' 32'' * E 33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "+ 30° 31' 32'' * E 33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' * -33° 34' 35''", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "30° 31' 32'' * - 33° 34' 35''", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "30° 31' 32'' * +33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' * + 33° 34' 35''", :location => location(30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' S * 33° 34' 35'' E", :location => location(-30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * 33° 34' 35'' W", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "S 30° 31' 32'' * 33° 34' 35'' E", :location => location(-30, 31, 32, 33, 34, 35)
  it_parses_message "30° 31' 32'' N * W 33° 34' 35''", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "at 30° 31' 32'' N * W 33° 34' 35''", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "l: 30° 31' 32'' N * W 33° 34' 35''", :location => location(30, 31, 32, -33, 34, 35)
  it_parses_message "1 2 3 N 4 W", :location => location(1, 2, 3, -4, 0, 0)
  it_parses_message "1 2 N 4 W", :location => location(1, 2, 0, -4, 0, 0)
  it_parses_message "1 N 4 E", :location => location(1, 0, 0, 4, 0, 0)
  it_parses_message "N 1 E 4", :location => location(1, 0, 0, 4, 0, 0)
  it_parses_message "12.24 N 45.67 E", :location => location(12.24, 0, 0, 45.67, 0, 0)
  it_parses_message "at N 1 E 4", :location => location(1, 0, 0, 4, 0, 0)
  it_parses_message "l: N 1 E 4", :location => location(1, 0, 0, 4, 0, 0)
  it_parses_message "+10 25 +2", :location => location(10, 25, 0, 2, 0, 0)
  # TODO USNG
  it_parses_message "Hello All!", :body => "Hello All!"
  it_parses_message "Hey, we should tell @somegroup about this!", :body => "Hey, we should tell @somegroup about this!", :mentions => ['somegroup']

  it_parses_help "help", :node => nil
  it_parses_help ".help", :node => nil
  it_parses_help "#help", :node => nil
  it_parses_help "h", :node => nil
  it_parses_help ".h", :node => nil
  it_parses_help "#h", :node => nil
  it_parses_help "?", :node => nil
  it_parses_help ".im", :node => LoginNode
  it_parses_help ".im username", :node => LoginNode
  it_parses_help "#im", :node => LoginNode
  it_parses_help "#im username", :node => LoginNode
  it_parses_help "invite help", :node => InviteNode
  it_parses_help "invite ?", :node => InviteNode
  it_parses_help "invite", :node => InviteNode
  it_parses_help ".i help", :node => InviteNode
  it_parses_help ".i ?", :node => InviteNode
  it_parses_help ".i", :node => InviteNode
  it_parses_help "#i help", :node => InviteNode
  it_parses_help "#i ?", :node => InviteNode
  it_parses_help "#i", :node => InviteNode
  it_parses_help "#my", :node => MyNode
  it_parses_help ".my", :node => MyNode
  it_parses_help "owner help", :node => OwnerNode
  it_parses_help "help owner", :node => OwnerNode
  it_parses_help "help group owner", :node => OwnerNode
  it_parses_help "help owner group", :node => OwnerNode
  it_parses_help "owner ?", :node => OwnerNode
  it_parses_help "? owner", :node => OwnerNode
  it_parses_help "owner", :node => OwnerNode
  it_parses_help ".ow ?", :node => OwnerNode
  it_parses_help "? .ow", :node => OwnerNode
  it_parses_help "block help", :node => BlockNode
  it_parses_help "help block", :node => BlockNode
  it_parses_help "block ?", :node => BlockNode
  it_parses_help "? block", :node => BlockNode
  it_parses_help "block", :node => BlockNode
  it_parses_help "lang help", :node => LanguageNode
  it_parses_help "help lang", :node => LanguageNode
  it_parses_help "help .lang", :node => LanguageNode
  it_parses_help "help #lang", :node => LanguageNode
  it_parses_help "lang ?", :node => LanguageNode
  it_parses_help ".lang ?", :node => LanguageNode
  it_parses_help "#lang ?", :node => LanguageNode
  it_parses_help "? lang", :node => LanguageNode
  it_parses_help "lang", :node => LanguageNode
  it_parses_help ".lang", :node => LanguageNode
  it_parses_help "#lang", :node => LanguageNode
  it_parses_help "_", :node => LanguageNode
  it_parses_help "_ ?", :node => LanguageNode
  it_parses_help "? _", :node => LanguageNode
  it_parses_help "help create", :node => CreateGroupNode
  it_parses_help "help creategroup", :node => CreateGroupNode
  it_parses_help "help create group", :node => CreateGroupNode
  it_parses_help "? create", :node => CreateGroupNode
  it_parses_help "create help", :node => CreateGroupNode
  it_parses_help "create ?", :node => CreateGroupNode
  it_parses_help "create group help", :node => CreateGroupNode
  it_parses_help "creategroup help", :node => CreateGroupNode
  it_parses_help ".cg help", :node => CreateGroupNode
  it_parses_help "#cg help", :node => CreateGroupNode
  it_parses_help "help .cg", :node => CreateGroupNode
  it_parses_help "help *", :node => CreateGroupNode
  it_parses_help "* help", :node => CreateGroupNode
  it_parses_help "help join", :node => JoinNode
  it_parses_help "join help", :node => JoinNode
  it_parses_help "join group help", :node => JoinNode
  it_parses_help "help join group", :node => JoinNode
  it_parses_help "help >", :node => JoinNode
  it_parses_help "> help", :node => JoinNode
  it_parses_help "help leave", :node => LeaveNode
  it_parses_help "leave help", :node => LeaveNode
  it_parses_help "leave group help", :node => LeaveNode
  it_parses_help "help leave group", :node => LeaveNode
  it_parses_help "help <", :node => LeaveNode
  it_parses_help "< help", :node => LeaveNode
  it_parses_help "help login", :node => LoginNode
  it_parses_help "login help", :node => LoginNode
  it_parses_help "? login", :node => LoginNode
  it_parses_help "login ?", :node => LoginNode
  it_parses_help "( ?", :node => LoginNode
  it_parses_help "help (", :node => LoginNode
  it_parses_help "help logout", :node => LogoutNode
  it_parses_help "logout help", :node => LogoutNode
  it_parses_help "? logout", :node => LogoutNode
  it_parses_help "logout ?", :node => LogoutNode
  it_parses_help ") ?", :node => LogoutNode
  it_parses_help "help )", :node => LogoutNode
  it_parses_help "help stop", :node => OffNode
  it_parses_help "? stop", :node => OffNode
  it_parses_help "stop help", :node => OffNode
  it_parses_help "stop ?", :node => OffNode
  it_parses_help "help on", :node => OnNode
  it_parses_help "? on", :node => OnNode
  it_parses_help "on help", :node => OnNode
  it_parses_help "on ?", :node => OnNode
  it_parses_help "name help", :node => SignupNode
  it_parses_help "help name", :node => SignupNode
  it_parses_help "name ?", :node => SignupNode
  it_parses_help "? name", :node => SignupNode
  it_parses_help "whois ?", :node => WhoIsNode
  it_parses_help "help whois", :node => WhoIsNode
  it_parses_help "whois help", :node => WhoIsNode
  it_parses_help "? whois", :node => WhoIsNode
  it_parses_help "whereis ?", :node => WhereIsNode
  it_parses_help "help whereis", :node => WhereIsNode
  it_parses_help "whereis help", :node => WhereIsNode
  it_parses_help "? whereis", :node => WhereIsNode

end
