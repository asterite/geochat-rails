class Parser < Lexer
  def initialize(string)
    super
  end

  def self.parse(string)
    Parser.new(string).parse
  end

  def parse
    # Signup
    if scan /^\s*(?:#|\.)*?\s*(?:name|n)\s*@?(.+?)\s*$/i
      return new_signup self[1].strip
    elsif scan /^\s*'(.+)'?$/i
      str = self[1].strip
      str = str[0 ... -1] if str[-1] == "'"
      return new_signup str.strip
    end

    # Login
    if scan /^\s*(?:#|\.)*?\s*(?:login|log\s+in|li|iam|i\s+am|i'm|im|\()\s*(?:@\s*)?(.+?)\s+(.+?)\s*$/i
      return LoginNode.new :login => self[1], :password => self[2]
    end

    # Logout
    if scan /^\s*(?:#|\.)*?\s*(logout|log\s*out|lo|bye)\s*$/i
      return LogoutNode.new
    elsif scan /^\s*\)\s*$/i
      return LogoutNode.new
    end

    # On
    if scan /^\s*(?:#|\.)*?\s*(on|start)\s*/i
      return OnNode.new
    elsif scan /^\s*\!\s*$/i
      return OnNode.new
    end

    # Off
    if scan /^\s*(?:#|\.)*?\s*(off|stop)\s*$/i
      return OffNode.new
    elsif scan /^\s*-\s*$/i
      return OnNode.new
    end
  end

  def new_signup(string)
    SignupNode.new :display_name => string, :suggested_login => string.gsub(/\s/, '_')
  end
end

class Node
  def initialize(attrs = {})
    attrs.each do |k, v|
      send "#{k}=", v
    end
  end
end

class SignupNode < Node
  attr_accessor :display_name
  attr_accessor :suggested_login
end

class LoginNode < Node
  attr_accessor :login
  attr_accessor :password
end

class LogoutNode < Node
end

class OnNode < Node
end

class OffNode < Node
end
