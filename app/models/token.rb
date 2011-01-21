# coding: utf-8

class Token
  Star = '*'
  Underscore = '_'
  Dot = '.'
  Comma = ','
  Colon = ':'
  Pound = '#'
  Slash = '/'
  Degrees = '°'
  SingleQuote = "'"
  DoubleQuote = "''"
  Exclamation = '!'
  Minus = '-'
  Plus = '+'
  GreaterThan = '>'
  LessThan = '<'
  LeftParen = '('
  RightParen = ')'
  Dollar = '$'
  Question = '?'

  [
    :Whitespace,
    :Number,
    :ThreeDotsNumber,
    :FourDotsNumber,
    :Name,
    :Login,
    :Logout,
    :Log,
    :In,
    :Im,
    :Li,
    :I,
    :Iam,
    :Am,
    :Bye,
    :Block,
    :Lo,
    :On,
    :Off,
    :Start,
    :Stop,
    :Create,
    :Group,
    :Cg,
    :Creategroup,
    :Invite,
    :J,
    :Join,
    :L,
    :Leave,
    :Ow,
    :Owner,
    :Is,
    :B,
    :Blast,
    :At,
    :S,
    :N,
    :E,
    :W,
    :R,
    :H,
    :Help,
    :NumberWord,
    :Phone,
    :Phonenumber,
    :Mobile,
    :Mobilenumber,
    :Location,
    :My,
    :Email,
    :Password,
    :G,
    :Groups,
    :Public,
    :Private,
    :Visible,
    :Nochat,
    :Chat,
    :Chatroom,
    :Alert,
    :Nohide,
    :Hide,
    :Wh,
    :Wi,
    :Who,
    :Where,
    :Whereis,
    :Whois,
    :Lang,
    :AtTarget,
    :Identifier,
    :EOF
  ].each do |name|
    eval "#{name} = :#{name}"
  end

  attr_accessor :next
  attr_accessor :start
  attr_accessor :value
  attr_accessor :string
  attr_accessor :positive
  attr_accessor :signed
  attr_accessor :decimal

  alias_method :positive?, :positive
  alias_method :signed?, :signed
  alias_method :decimal?, :decimal

  def negative?
    !positive?
  end

  def unsigned?
    !signed?
  end

  def integer?
    !decimal?
  end
end

