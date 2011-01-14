# coding: utf-8

require 'test_helper'

class LexerTest < ActiveSupport::TestCase
  def self.it_lexes_token(str, token_value)
    test "lexes #{str}" do
      lex = Lexer.new str
      tok = lex.next_token
      assert_equal token_value, tok.value
      assert_equal str, tok.string
    end
  end

  def self.it_lexes_string(str, sym = nil)
    test "lexes string #{str.downcase}" do
      lex = Lexer.new str.downcase
      tok = lex.next_token
      sym ||= str.downcase.capitalize
      assert_equal eval("Token::#{sym}"), tok.value
      assert_equal str.downcase, tok.string
    end

    test "lexes string #{str.upcase}" do
      lex = Lexer.new str.upcase
      tok = lex.next_token
      sym ||= str.downcase.capitalize
      assert_equal eval("Token::#{sym}"), tok.value
      assert_equal str.upcase, tok.string
    end
  end

  def self.it_lexes_identifier(str, options = {})
    test "lexes identifier #{str}" do
      lex = Lexer.new str.downcase
      tok = lex.next_token
      assert_equal Token::Identifier, tok.value
      assert_equal (options[:as] || str), tok.string
    end
  end

  def self.it_lexes_whitespace(str)
    test "lexes whitespace #{str.length}" do
      lex = Lexer.new str
      tok = lex.next_token
      assert_equal Token::Whitespace, tok.value
      assert_equal str, tok.string
    end
  end

  def self.it_lexes_number(str, *specs)
    test "lexes number #{str}" do
      lex = Lexer.new str
      tok = lex.next_token
      assert_equal Token::Number, tok.value
      assert_equal str, tok.string
      specs.each do |spec|
        assert tok.send("#{spec}?"), "#{str} expected to be #{spec}"
      end
    end
  end

  def self.it_lexes_three_dots_number(str)
    it_lexes_token str, Token::ThreeDotsNumber
  end

  def self.it_lexes_four_dots_number(str)
    it_lexes_token str, Token::FourDotsNumber
  end

  it_lexes_token "*", Token::Star
  it_lexes_token "_", Token::Underscore
  it_lexes_token ".", Token::Dot
  it_lexes_token ",", Token::Comma
  it_lexes_token ":", Token::Colon
  it_lexes_token "#", Token::Pound
  it_lexes_token "/", Token::Slash
  it_lexes_token "°", Token::Degrees
  it_lexes_token "º", Token::Degrees
  it_lexes_token "'", Token::SingleQuote
  it_lexes_token "''", Token::DoubleQuote
  it_lexes_token "!", Token::Exclamation
  it_lexes_token "-", Token::Minus
  it_lexes_token "+", Token::Plus
  it_lexes_token ">", Token::GreaterThan
  it_lexes_token "<", Token::LessThan
  it_lexes_token "(", Token::LeftParen
  it_lexes_token ")", Token::RightParen
  it_lexes_token "$", Token::Dollar
  it_lexes_token "?", Token::Question

  it_lexes_string 'name'
  it_lexes_string 'login'
  it_lexes_string 'logout'
  it_lexes_string 'log'
  it_lexes_string 'in'
  it_lexes_string 'im'
  it_lexes_string "i'm", :Im
  it_lexes_string "li"
  it_lexes_string "i"
  it_lexes_string "iam"
  it_lexes_string "am"
  it_lexes_string "bye"
  it_lexes_string "block"
  it_lexes_string "lo"
  it_lexes_string "on"
  it_lexes_string "off"
  it_lexes_string "start"
  it_lexes_string "stop"
  it_lexes_string "create"
  it_lexes_string "group"
  it_lexes_string "cg"
  it_lexes_string "creategroup"
  it_lexes_string "invite"
  it_lexes_string "j"
  it_lexes_string "join"
  it_lexes_string "l"
  it_lexes_string "leave"
  it_lexes_string "ow"
  it_lexes_string "owner"
  it_lexes_string "is"
  it_lexes_string "b"
  it_lexes_string "blast"
  it_lexes_string "at"
  it_lexes_string "s"
  it_lexes_string "n"
  it_lexes_string "e"
  it_lexes_string "w"
  it_lexes_string "h"
  it_lexes_string "r"
  it_lexes_string "help"
  it_lexes_string "number", :NumberWord
  it_lexes_string "phone"
  it_lexes_string "phonenumber"
  it_lexes_string "mobile"
  it_lexes_string "mobilenumber"
  it_lexes_string "location"
  it_lexes_string "my"
  it_lexes_string "email"
  it_lexes_string "password"
  it_lexes_string "g"
  it_lexes_string "groups"
  it_lexes_string "public"
  it_lexes_string "private"
  it_lexes_string "visible"
  it_lexes_string "nochat"
  it_lexes_string "chat"
  it_lexes_string "chatroom"
  it_lexes_string "alert"
  it_lexes_string "nohide"
  it_lexes_string "hide"
  it_lexes_string "wh"
  it_lexes_string "wi"
  it_lexes_string "who"
  it_lexes_string "where"
  it_lexes_string "whereis"
  it_lexes_string "whois"
  it_lexes_string "lang"

  it_lexes_token "@group", Token::AtTarget

  it_lexes_whitespace ' '
  it_lexes_whitespace '  '
  it_lexes_whitespace ' \n\t '

  it_lexes_number '1', :positive, :unsigned, :integer
  it_lexes_number '1234', :positive, :unsigned, :integer
  it_lexes_number '12.34', :positive, :unsigned, :decimal
  it_lexes_number '+12.34', :positive, :signed, :decimal
  it_lexes_number '-12.34', :negative, :signed, :decimal
  it_lexes_number '-12,34', :negative, :signed, :decimal

  it_lexes_three_dots_number '12.34.56'
  it_lexes_three_dots_number '12,34,56'
  it_lexes_three_dots_number '+12.34.56'
  it_lexes_three_dots_number '-12,34,56'

  it_lexes_four_dots_number '12.34.56.78'
  it_lexes_four_dots_number '12,34,56,78'
  it_lexes_four_dots_number '+12.34.56.78'
  it_lexes_four_dots_number '-12,34,56,78'

  it_lexes_identifier "support"
  it_lexes_identifier "hola"
  it_lexes_identifier "jo"
  it_lexes_identifier "creat"
  it_lexes_identifier "foo.", :as => 'foo'
  it_lexes_identifier "foo,", :as => 'foo'
  it_lexes_identifier "foo!", :as => 'foo'
  it_lexes_identifier "foo?", :as => 'foo'
  it_lexes_identifier "foo'", :as => 'foo'
  it_lexes_identifier "foo\"", :as => 'foo'
  it_lexes_identifier "foo(", :as => 'foo'
  it_lexes_identifier "foo)", :as => 'foo'
  it_lexes_identifier "foo[", :as => 'foo'
  it_lexes_identifier "foo]", :as => 'foo'
  it_lexes_identifier "foo{", :as => 'foo'
  it_lexes_identifier "foo}", :as => 'foo'
  it_lexes_identifier "foo<", :as => 'foo'
  it_lexes_identifier "foo>", :as => 'foo'
  it_lexes_identifier "foo+", :as => 'foo'
  it_lexes_identifier "foo*", :as => 'foo'
  it_lexes_identifier "foo&", :as => 'foo'
  it_lexes_identifier "foo$", :as => 'foo'
  it_lexes_identifier "foo#", :as => 'foo'
  it_lexes_identifier "foo=", :as => 'foo'
  it_lexes_identifier "foo/", :as => 'foo'
  it_lexes_identifier "foo\\", :as => 'foo'
  it_lexes_identifier "foo:", :as => 'foo'
  it_lexes_identifier "foo;", :as => 'foo'
  it_lexes_identifier "foo^", :as => 'foo'
  it_lexes_identifier "foo@", :as => 'foo'
  it_lexes_identifier "foo@bar.baz"
  it_lexes_identifier "foo.man@bar.baz"
  it_lexes_identifier "http://geochat.instedd.org/foo/bar"
  it_lexes_identifier "mailto://geochat.instedd.org/foo/bar"
  it_lexes_identifier "123foo"
  it_lexes_identifier "foo/bar"

  test "it lexes EOF" do
    assert_equal Token::EOF, Lexer.new('').next_token.value
  end
end
