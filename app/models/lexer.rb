# coding: utf-8

require 'strscan'

class Lexer < StringScanner
  def initialize(str)
    super
    @token = Token.new
  end

  def next_token
    @token.start = pos
    @token.string = nil
    @token.value = nil

    if eos?
      @token.value = Token::EOF
    elsif scan /(\s|\\n|\\r|\\t)+/
      @token.value = Token::Whitespace
    elsif scan /\*/
      @token.value = Token::Star
    elsif scan /_/
      @token.value = Token::Underscore
    elsif scan /\./
      @token.value = Token::Dot
    elsif scan /,/
      @token.value = Token::Comma
    elsif scan /:/
      @token.value = Token::Colon
    elsif scan /#/
      @token.value = Token::Pound
    elsif scan /\//
      @token.value = Token::Slash
    elsif scan(/°/) || scan(/º/)
      @token.value = Token::Degrees
    elsif scan /''/
      @token.value = Token::DoubleQuote
    elsif scan /'/
      @token.value = Token::SingleQuote
    elsif scan /!/
      @token.value = Token::Exclamation
    elsif scan(/(\+|-)?\d+\.\d+\.\d+\.\d+\b/) || scan(/(\+|-)?\d+,\d+,\d+,\d+\b/)
      @token.value = Token::FourDotsNumber
    elsif scan(/(\+|-)?\d+\.\d+\.\d+\b/) || scan(/(\+|-)?\d+,\d+,\d+\b/)
      @token.value = Token::ThreeDotsNumber
    elsif scan /(\+|-)?\d+((\.|,)\d+)?\b/
      @token.value = Token::Number
      @token.positive = self[1].nil? || self[1] == '+'
      @token.signed = !self[1].nil?
      @token.decimal = !self[2].nil?
    elsif scan /-/
      @token.value = Token::Minus
    elsif scan /\+/
      @token.value = Token::Plus
    elsif scan />/
      @token.value = Token::GreaterThan
    elsif scan /</
      @token.value = Token::LessThan
    elsif scan /\(/
      @token.value = Token::LeftParen
    elsif scan /\)/
      @token.value = Token::RightParen
    elsif scan /\$/
      @token.value = Token::Dollar
    elsif scan /\?/
      @token.value = Token::Question
    elsif scan(/\@(\w|-)+\b/i)
      @token.value = Token::AtTarget
    elsif scan(/alert\b/i)
      @token.value = Token::Alert
    elsif scan(/am\b/i)
      @token.value = Token::Am
    elsif scan(/at\b/i)
      @token.value = Token::At
    elsif scan(/b\b/i)
      @token.value = Token::B
    elsif scan(/blast\b/i)
      @token.value = Token::Blast
    elsif scan(/block\b/i)
      @token.value = Token::Block
    elsif scan(/bye\b/i)
      @token.value = Token::Bye
    elsif scan(/cg\b/i)
      @token.value = Token::Cg
    elsif scan(/chat\b/i)
      @token.value = Token::Chat
    elsif scan(/chatroom\b/i)
      @token.value = Token::Chatroom
    elsif scan(/create\b/i)
      @token.value = Token::Create
    elsif scan(/creategroup\b/i)
      @token.value = Token::Creategroup
    elsif scan(/email\b/i)
      @token.value = Token::Email
    elsif scan(/e\b/i)
      @token.value = Token::E
    elsif scan(/g\b/i)
      @token.value = Token::G
    elsif scan(/group\b/i)
      @token.value = Token::Group
    elsif scan(/groups\b/i)
      @token.value = Token::Groups
    elsif scan(/h\b/i)
      @token.value = Token::H
    elsif scan(/help\b/i)
      @token.value = Token::Help
    elsif scan(/hide\b/i)
      @token.value = Token::Hide
    elsif scan(/im\b/i) || scan(/i'm\b/i)
      @token.value = Token::Im
    elsif scan(/i\b/i)
      @token.value = Token::I
    elsif scan(/iam\b/i)
      @token.value = Token::Iam
    elsif scan /in\b/i
      @token.value = Token::In
    elsif scan(/invite\b/i)
      @token.value = Token::Invite
    elsif scan /is\b/i
      @token.value = Token::Is
    elsif scan(/join\b/i)
      @token.value = Token::Join
    elsif scan(/j\b/i)
      @token.value = Token::J
    elsif scan(/l\b/i)
      @token.value = Token::L
    elsif scan(/lang\b/i)
      @token.value = Token::Lang
    elsif scan(/leave\b/i)
      @token.value = Token::Leave
    elsif scan(/li\b/i)
      @token.value = Token::Li
    elsif scan(/lo\b/i)
      @token.value = Token::Lo
    elsif scan(/location\b/i)
      @token.value = Token::Location
    elsif scan /log\b/i
      @token.value = Token::Log
    elsif scan /login\b/i
      @token.value = Token::Login
    elsif scan /logout\b/i
      @token.value = Token::Logout
    elsif scan /mobile\b/i
      @token.value = Token::Mobile
    elsif scan /mobilenumber\b/i
      @token.value = Token::Mobilenumber
    elsif scan /my\b/i
      @token.value = Token::My
    elsif scan /n\b/i
      @token.value = Token::N
    elsif scan /name\b/i
      @token.value = Token::Name
    elsif scan(/nochat\b/i)
      @token.value = Token::Nochat
    elsif scan(/nohide\b/i)
      @token.value = Token::Nohide
    elsif scan /number\b/i
      @token.value = Token::NumberWord
    elsif scan(/off\b/i)
      @token.value = Token::Off
    elsif scan(/on\b/i)
      @token.value = Token::On
    elsif scan(/ow\b/i)
      @token.value = Token::Ow
    elsif scan(/owner\b/i)
      @token.value = Token::Owner
    elsif scan(/password\b/i)
      @token.value = Token::Password
    elsif scan(/phone\b/i)
      @token.value = Token::Phone
    elsif scan(/phonenumber\b/i)
      @token.value = Token::Phonenumber
    elsif scan(/private\b/i)
      @token.value = Token::Private
    elsif scan(/public\b/i)
      @token.value = Token::Public
    elsif scan(/r\b/i)
      @token.value = Token::R
    elsif scan(/s\b/i)
      @token.value = Token::S
    elsif scan(/start\b/i)
      @token.value = Token::Start
    elsif scan(/stop\b/i)
      @token.value = Token::Stop
    elsif scan(/visible\b/i)
      @token.value = Token::Visible
    elsif scan(/w\b/i)
      @token.value = Token::W
    elsif scan(/wh\b/i)
      @token.value = Token::Wh
    elsif scan(/where\b/i)
      @token.value = Token::Where
    elsif scan(/whereis\b/i)
      @token.value = Token::Whereis
    elsif scan(/wi\b/i)
      @token.value = Token::Wi
    elsif scan(/who\b/i)
      @token.value = Token::Who
    elsif scan(/whois\b/i)
      @token.value = Token::Whois
    elsif scan /.+?\@.+?(\..+?)*\b/
      @token.value = Token::Identifier
    elsif scan(/.+?:\/\/.+?\s/) || scan(/.+?:\/\/.+\b/)
      @token.value = Token::Identifier
    elsif scan /.+?(\/.+)+\b/
      @token.value = Token::Identifier
    else
      scan /.+?\b/
      @token.value = Token::Identifier
    end

    @token.string = matched.to_s

    @token
  end
end
