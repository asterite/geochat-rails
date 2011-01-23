class Parser < Lexer
  def initialize(string, lookup)
    super(string)
    @lookup = lookup
  end

  def self.parse(string, lookup)
    Parser.new(string, lookup).parse
  end

  def parse
    # Check if first token is a group
    if scan /^\s*(.+?)\s+(.+?)$/i
      group = self[1]
      if @lookup.is_group? group
        rest = StringScanner.new self[2]

        # Invite
        if rest.scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+(.+?)$/i
          return InviteNode.new :group => group, :users => rest[1].split.without_prefix!('+')
        end

        # Block
        if rest.scan /^\s*(?:#|\.)*?\s*block\s+(\S+)$/i
          return BlockNode.new :group => group, :user => rest[1]
        end

        # Owner
        if rest.scan /^\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)\s+(\S+)$/i
          return OwnerNode.new :group => group, :user => rest[1]
        elsif rest.scan /^\s*\$\s*(\S+)$/i
          return OwnerNode.new :group => group, :user => rest[1]
        end

        return MessageNode.new :targets => [group], :body => rest.string
      end

      unscan
    end

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
    elsif scan /^\s*(?:#|\.)*?\s*(.im)(\s+\S+)?\s*$/i
      return HelpNode.new :node => LoginNode
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
    if scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)(\s+(help|\?))?\s*$/i
      return HelpNode.new :node => InviteNode
    elsif scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+\+?(\d+\s+\+?\d+\s+.+?)$/i
      users = self[1].split.without_prefix! '+'
      return InviteNode.new :users => users
    elsif scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+\+?(\d+)\s+(?:@\s*)?(.+?)$/i
      return InviteNode.new :users => [self[1].strip], :group => self[2].strip
    elsif scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+(?:@\s*)?(.+?)\s+\+?(\d+\s*.*?)$/i
      group = self[1].strip
      users = self[2].split.without_prefix! '+'
      return InviteNode.new :users => users, :group => group
    elsif scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+@\s*(.+?)\s+(.+?)$/i
      users = [self[1].strip]
      group = self[2].strip
      return InviteNode.new :users => users, :group => group
    elsif scan /^\s*(?:invite|\.invite|\#invite|\.i|\#i)\s+(.+?)$/i
      pieces = self[1].split.without_prefix! '@'
      group, *users = pieces
      group, users = nil, [group] if users.empty?
      return InviteNode.new :users => users, :group => group
    elsif scan /^\s*@\s*(.+?)\s+(?:invite|\.invite|\#invite|\.i|\#i)\s+(.+?)$/i
      users = self[2].split
      return InviteNode.new :users => users, :group => self[1].strip
    elsif scan /^\s*\+\s*(.+?)$/i
      return InviteNode.new :users => self[1].split
    elsif scan /^\s*@\s*(.+?)\s+\+\s*(.+?)$/i
      return InviteNode.new :users => self[2].split, :group => self[1].strip
    end

    # Join
    if scan /^\s*(?:join|join\s+group|\.\s*j|\.\s*join|\#\s*j|\#\s*join)\s+(?:@\s*)?(\S+)$/i
      return JoinNode.new :group => self[1]
    elsif scan /^\s*>\s*(?:@\s*)?(\S+)$/i
      return JoinNode.new :group => self[1]
    end

    # Leave
    if scan /^\s*(?:leave|leave\s+group|\.\s*l|\.\s*leave|\#\s*l|\#\s*leave)\s+(?:@\s*)?(\S+)$/i
      return LeaveNode.new :group => self[1]
    elsif scan /^\s*<\s*(?:@\s*)?(\S+)$/i
      return LeaveNode.new :group => self[1]
    end

    # Block
    if scan /^\s*(?:#|\.)*?\s*block\s+(?:@\s*)?(\S+)$/i
      return BlockNode.new :user => self[1]
    elsif scan /^\s*(?:#|\.)*?\s*block\s+(\S+)\s+(\S+)$/i
      return BlockNode.new :user => self[1], :group => self[2]
    elsif scan /^\s*@\s*(\S+)\s*(?:#|\.)*?\s*block\s+(\S+)$/i
      return BlockNode.new :user => self[2], :group => self[1]
    end

    # Owner
    if scan /^\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)(\s+(?:help|\?))?\s*$/i
      return HelpNode.new :node => OwnerNode
    elsif scan /^\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)\s+(?:@\s*)?(\S+)$/i
      return OwnerNode.new :user => self[1]
    elsif scan /^\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)\s+(?:@\s*)?(\S+)\s+(?:\+\s*)?(\d+)$/i
      return OwnerNode.new :user => self[2], :group => self[1]
    elsif scan /^\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)\s+(?:@\s*)?(\S+)\s+(?:@\s*)?(\S+)$/i
      return OwnerNode.new :user => self[1], :group => self[2]
    elsif scan /^\s*@\s*(\S+)\s*(?:#|\.)*?\s*(?:owner|.owner|.ow|#owner|#ow)\s+(\S+)$/i
      return OwnerNode.new :user => self[2], :group => self[1]
    elsif scan /^\s*\$\s*(\S+)\s*$/i
      return OwnerNode.new :user => self[1]
    elsif scan /^\s*\$\s*(\S+)\s+(\S+)\s*$/i
      return OwnerNode.new :user => self[1], :group => self[2]
    end

    # My
    if scan /^\s*(?:#|\.)*\s*my\s*$/i
      return HelpNode.new :node => MyNode
    elsif scan /^\s*(?:#|\.)*\s*my\s+groups\s*$/i
      return MyNode.new :key => MyNode::Groups
    elsif scan /^\s*(?:#|\.)*\s*my\s+(?:group|g)\s*$/i
      return MyNode.new :key => MyNode::Group
    elsif scan /^\s*(?:#|\.)*\s*my\s+(?:group|g)\s+(?:@\s*)?(\S+)\s*$/i
      return MyNode.new :key => MyNode::Group, :value => self[1].strip
    elsif scan /^\s*(?:#|\.)*\s*my\s+name\s*$/i
      return MyNode.new :key => MyNode::Name
    elsif scan /^\s*(?:#|\.)*\s*my\s+name\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Name, :value => self[1].strip
    elsif scan /^\s*(?:#|\.)*\s*my\s+email\s*$/i
      return MyNode.new :key => MyNode::Email
    elsif scan /^\s*(?:#|\.)*\s*my\s+email\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Email, :value => self[1].strip
    elsif scan /^\s*(?:#|\.)*\s*my\s+(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*$/i
      return MyNode.new :key => MyNode::Number
    elsif scan /^\s*(?:#|\.)*\s*my\s+location\s*$/i
      return MyNode.new :key => MyNode::Location
    elsif scan /^\s*(?:#|\.)*\s*my\s+location\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Location, :value => self[1].strip
    elsif scan /^\s*(?:#|\.)*\s*my\s+login\s*$/i
      return MyNode.new :key => MyNode::Login
    elsif scan /^\s*(?:#|\.)*\s*my\s+login\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Login, :value => self[1]
    elsif scan /^\s*(?:#|\.)*\s*my\s+password\s*$/i
      return MyNode.new :key => MyNode::Password
    elsif scan /^\s*(?:#|\.)*\s*my\s+password\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Password, :value => self[1]
    end

    # Who is
    if scan /^\s*(?:#|\.)*\s*(?:whois|wi)\s+(?:@\s*)?(.+?)\s*\??\s*$/i
      return WhoIsNode.new :user => self[1].strip
    end

    # Help
    if scan /^\s*(?:#|\.)*\s*(?:help|h|\?)\s*$/i
      return HelpNode.new
    elsif scan /^\s*(?:#|\.)*\s*(?:help|h|\?)\s+(owner|group\s+owner|owner\s+group|\.ow|#ow|\.owner|#owner)$/i
      return HelpNode.new :node => OwnerNode
    end

    # Message
    if scan /^\s*@\s*(.+?)\s+(.+?)$/i
      return MessageNode.new :body => self[2], :targets => [self[1]]
    end

    MessageNode.new :body => string
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

class JoinNode < Node
  attr_accessor :group
end

class LeaveNode < Node
  attr_accessor :group
end

class MessageNode < Node
  attr_accessor :body
  attr_accessor :targets
end

class HelpNode < Node
  attr_accessor :node
end

class BlockNode < Node
  attr_accessor :user
  attr_accessor :group
end

class OwnerNode < Node
  attr_accessor :user
  attr_accessor :group
end

class MyNode < Node
  attr_accessor :key
  attr_accessor :value

  Groups = :groups
  Group = :group
  Name = :name
  Email = :email
  Login = :login
  Password = :password
  Number = :number
  Location = :location
end

class WhoIsNode < Node
  attr_accessor :user
end
