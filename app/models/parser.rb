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
      return OffNode.new
    end

    # Create group
    if scan /^\s*(?:#|\.)*?\s*(?:create\s+group|create|creategroup|cg)\s+(?:@\s*)?(.+?)(\s+.+?)?$/i
      return new_create_group self[1], self[2]
    elsif scan /^\s*\*\s*(?:@\s*)?(.+?)(\s+.+?)?$/i
      return new_create_group self[1], self[2]
    end

    # Invite
    if scan /^\s*invite\s+\+?(\d+\s+\+?\d+\s+.+?)$/i
      users = self[1].split.map!{|x| x.start_with?('+') ? x[1 .. -1] : x}
      return InviteNode.new :users => users
    elsif scan /^\s*invite\s+(\d+)\s+(?:@\s*)?(.+?)$/i
      return InviteNode.new :users => [self[1].strip], :group => self[2].strip
    elsif scan /^\s*invite\s+(?:@\s*)?(.+?)\s+\+?(\d+\s*.*?)$/i
      group = self[1].strip
      users = self[2].split.map!{|x| x.start_with?('+') ? x[1 .. -1] : x}
      return InviteNode.new :users => users, :group => group
    elsif scan /^\s*invite\s+@\s*(.+?)\s+(.+?)$/i
      users = [self[1].strip]
      group = self[2].strip
      return InviteNode.new :users => users, :group => group
    elsif scan /^\s*invite\s+(.+?)$/i
      pieces = self[1].split
      pieces.map!{|x| x.start_with?('@') ? x[1 .. -1] : x}
      group, *users = pieces
      group, users = nil, [group] if users.empty?
      return InviteNode.new :users => users, :group => group
    end
  end

  def new_signup(string)
    SignupNode.new :display_name => string, :suggested_login => string.gsub(/\s/, '_')
  end

  def new_create_group(group_alias, pieces)
    options = {:group => self[1], :public => false, :nochat => false}
    if pieces
      pieces = pieces.split
      in_name = false
      name = nil
      pieces.each do |piece|
        down = piece.downcase
        case down
        when 'name'
          in_name = true
          name = ''
        when 'nochat', 'alert'
          options[:nochat] = true
          in_name = false
        when 'public', 'nohide', 'visible'
          options[:public] = true
          in_name = false
        when 'chat', 'chatroom', 'hide', 'private'
          in_name = false
        else
          name << piece
          name << ' '
        end
      end
    end
    options[:name] = name.strip if name
    CreateGroupNode.new options
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

class CreateGroupNode < Node
  attr_accessor :group
  attr_accessor :public
  attr_accessor :nochat
  attr_accessor :name
end

class InviteNode < Node
  attr_accessor :group
  attr_accessor :users
end
