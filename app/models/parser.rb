# coding: utf-8

require 'strscan'

class Parser < StringScanner
  def initialize(string, lookup = nil, options = {})
    super(string)
    @lookup = lookup
    @parse_signup_and_join = options[:parse_signup_and_join]
  end

  def self.parse(string, lookup = nil, options = {})
    Parser.new(string, lookup, options).parse
  end

  def parse
    node = parse_node

    if node.is_a?(MessageNode) && node.body
      check_mentions node
      check_tags node
      check_locations node
    end
    node
  end

  def check_mentions(node)
    node.body.scan /\s+@\s*(\S+)/ do |match|
      node.mentions ||= []
      node.mentions << match.first
    end
  end

  def check_tags(node)
    node.body.scan /#\s*(\S+)/ do |match|
      node.tags ||= []
      node.tags << match.first
    end
  end

  def check_locations(node)
    node.body.scan /\s+\/[^\/]+\/|\s+\/\S+/ do |match|
      match = match.strip
      match = match[1 .. -1] if match.start_with?('/')
      ['/', ',', '.', ';'].each do |char|
        match = match[0 .. -2] if match.end_with?(char)
      end
      if match.present?
        node.locations ||= []
        node.locations << check_numeric_location(match)
      end
    end
  end

  def parse_node
    # Skip first spaces
    scan /\s*/

    # Ping
    node = command PingNode do
      name 'ping'
      args :text, :optional => true
      help :no
    end
    return node if node

    options = {}
    options[:blast] = check_blast

    # Check if first token is a group
    if scan /^(@)?\s*(.+?)\s+(.+?)$/i
      group = self[2]
      if (self[1] && target = UnknownTarget.new(group)) || (@lookup && target = @lookup.get_target(group))
        options[:targets] = [target]

        rest = StringScanner.new self[3]

        if !target.is_a?(UserTarget)

          # Invite
          node = rest.command InviteNode do
            name 'invite'
            name 'i', :prefix => :required
            name '\+', :prefix => :none, :space_after_command => false
            args :users
            change_args do |args|
              args[:group] = group
              args[:users] = args[:users].split.without_prefix! '+'
            end
          end
          return node if node

          # Block
          node = rest.command BlockNode do
            name 'block'
            args :user, :spaces_in_args => false
            change_args{|args| args[:group] = group}
          end
          return node if node

          # Owner
          node = rest.command OwnerNode do
            name 'owner', 'ow', :spaces_in_args => false
            name '\$', :space_after_command => false
            args :user
            change_args{|args| args[:group] = group}
          end
          return node if node
        end

        while rest.scan /^\s*(@)?\s*(.+?)\s+(.+?)$/i
          if rest[1]
            options[:targets] << UnknownTarget.new(rest[2])
            rest = StringScanner.new rest[3]
          elsif @lookup
            target = @lookup.get_target rest[2]
            if target
              options[:targets] << target
              rest = StringScanner.new rest[3]
            else
              rest.unscan
              break
            end
          else
            rest.unscan
            break
          end
        end

        self.string = rest.string

        node = parse_message_with_location options
        return node if node

        return MessageNode.new options.merge(:body => string)
      end

      unscan
    end

    # Help
    node = command HelpNode do
      name 'help', 'h', '\?'
      args :node, :optional => true
      change_args do |args|
        args[:node] = args[:node][1 .. -1] if args[:node].start_with?('.')
        args[:node] = case args[:node].downcase
                      when 'owner', 'group owner', 'owner group', 'ow'
                        OwnerNode
                      when 'block'
                       BlockNode
                      when 'lang', '_'
                        LanguageNode
                      when 'create', 'create group', 'creategroup', 'cg', '*'
                        CreateGroupNode
                      when  'join', 'join group', 'joingroup', 'j', '>'
                        JoinNode
                      when  'leave', 'leave group', 'leavegroup', 'l', '<'
                        LeaveNode
                      when 'log in', 'login', 'li', 'i am', 'iam', "i'm", 'im', '('
                        LoginNode
                      when 'log out', 'logout', 'log off', 'logoff', 'lo', 'bye', ')'
                        LogoutNode
                      when 'stop', 'off'
                        OffNode
                      when 'start', 'on'
                        OnNode
                      when 'name', 'n', 'signup'
                        SignupNode
                      when 'who is', 'whois', 'wh'
                        WhoIsNode
                      when 'whereis', 'where is', 'wi', 'w'
                        WhereIsNode
                      when 'my'
                        MyNode
                      when 'i', 'invite'
                        InviteNode
                      end
      end
    end
    return node if node

    node = parse_message_with_location options
    return node if node

    # Signup and join
    if scan /^(.+?)\s*>\s*(\S+)\s*$/i
      return new_signup self[1].strip, self[2]
    end

    if @parse_signup_and_join && scan(/^\s*(.+?)\s*(?:join|\!)\s*(\S+)\s*$/i)
      return new_signup self[1].strip, self[2]
    end

    # Signup
    node = command SignupNode do
      name 'name', 'signup'
      name 'n', :prefix => :required
      args :display_name
      change_args do |args|
        args[:suggested_login] = args[:display_name].gsub(/\s/, '')
      end
    end
    return node if node

    if scan /^'(.+)'?$/i
      str = self[1].strip
      str = str[0 ... -1] if str[-1] == "'"
      return new_signup str.strip
    end

    # Login
    node = command LoginNode do
      name 'login', 'log in', 'li', 'iam', 'i am', "i'm", 'im'
      name '\(', :space_after_command => false
      name 'li', :prefix => :required
      args :login, :password, :spaces_in_args => false
    end
    return node if node

    # Logout
    node = command LogoutNode do
      name 'logout', 'log out', 'logoff', 'log off', 'bye'
      name 'lo', :prefix => :required
      name '\)', :prefix => :none
    end
    return node if node

    # On
    node = command OnNode do
      name 'on', 'start'
      name '\!', :prefix => :none
    end
    return node if node

    # Off
    node = command OffNode do
      name 'off', 'stop'
      name '-', :prefix => :none
    end
    return node if node

    # Create group
    scan_command 'create', 'create group', 'creategroup', 'cg', '\*', :help => true do
      return HelpNode.new :node => CreateGroupNode
    end

    if scan /^(?:#|\.)*?\s*(?:create\s*group|create|cg)\s+(?:@\s*)?(.+?)(\s+.+?)?$/i
      return new_create_group self[1], self[2]
    elsif scan /^\*\s*(?:@\s*)?(.+?)(\s+.+?)?$/i
      return new_create_group self[1], self[2]
    end

    # Invite
    scan_command 'invite', 'i', :help => true do
      return HelpNode.new :node => InviteNode
    end

    if scan /^(?:invite|\.invite|\#invite|\.i|\#i)\s+\+?(\d+\s+\+?\d+\s+.+?)$/i
      users = self[1].split.without_prefix! '+'
      return InviteNode.new :users => users
    elsif scan /^(?:invite|\.invite|\#invite|\.i|\#i)\s+\+?(\d+)\s+(?:@\s*)?(.+?)$/i
      return InviteNode.new :users => [self[1].strip], :group => self[2].strip
    elsif scan /^(?:invite|\.invite|\#invite|\.i|\#i)\s+(?:@\s*)?(.+?)\s+\+?(\d+\s*.*?)$/i
      group = self[1].strip
      users = self[2].split.without_prefix! '+'
      return InviteNode.new :users => users, :group => group
    elsif scan /^(?:invite|\.invite|\#invite|\.i|\#i)\s+@\s*(.+?)\s+(.+?)$/i
      users = [self[1].strip]
      group = self[2].strip
      return InviteNode.new :users => users, :group => group
    elsif scan /^(?:invite|\.invite|\#invite|\.i|\#i)\s+(.+?)$/i
      pieces = self[1].split.without_prefix! '@'
      group, *users = pieces
      group, users = nil, [group] if users.empty?
      return InviteNode.new :users => users, :group => group
    elsif scan /^@\s*(.+?)\s+(?:invite|\.invite|\#invite|\.i|\#i)\s+(.+?)$/i
      users = self[2].split
      return InviteNode.new :users => users, :group => self[1].strip
    elsif scan /^\+\s*(.+?)$/i
      return InviteNode.new :users => self[1].split
    elsif scan /^@\s*(.+?)\s+\+\s*(.+?)$/i
      return InviteNode.new :users => self[2].split, :group => self[1].strip
    end

    # Join
    node = command JoinNode do
      name 'join', 'join group', 'joingroup'
      name 'j', :prefix => :required
      name '>', :space_after_command => false
      args :group, :spaces_in_args => false
    end
    return node if node

    # Leave
    node = command LeaveNode do
      name 'leave', 'leave group', 'leavegroup'
      name 'l', :prefix => :required
      name '<', :space_after_command => false
      args :group, :spaces_in_args => false
    end
    return node if node

    # Block
    node = command BlockNode do
      name 'block'
      args :user, :spaces_in_args => false
      args :user, :group, :spaces_in_args => false
    end
    return node if node

    # Owner
    node = command OwnerNode do
      name 'owner', 'ow'
      name '\$', :space_after_command => false
      args :user, :spaces_in_args => false
      args :user, :group, :spaces_in_args => false
    end
    return node if node

    # My
    if scan /^(?:#|\.)*\s*my\s*$/i
      return HelpNode.new :node => MyNode
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)(help|\?)\s*$/i
      return HelpNode.new :node => MyNode
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)groups\s*$/i
      return MyNode.new :key => MyNode::Groups
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)(?:group|g)\s*$/i
      return MyNode.new :key => MyNode::Group
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)(?:group|g)\s+(?:@\s*)?(\S+)\s*$/i
      return MyNode.new :key => MyNode::Group, :value => self[1].strip
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)name\s*$/i
      return MyNode.new :key => MyNode::Name
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)name\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Name, :value => self[1].strip
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)email\s*$/i
      return MyNode.new :key => MyNode::Email
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)email\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Email, :value => self[1].strip
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*$/i
      return MyNode.new :key => MyNode::Number
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*(.+?)\s*$/i
      return MyNode.new :key => MyNode::Number, :value => self[1].strip
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)location\s*$/i
      return MyNode.new :key => MyNode::Location
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)location\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Location, :value => check_numeric_location(self[1].strip)
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)login\s*$/i
      return MyNode.new :key => MyNode::Login
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)login\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Login, :value => self[1]
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)password\s*$/i
      return MyNode.new :key => MyNode::Password
    elsif scan /^(?:#|\.)*\s*my(?:\s+|_*)password\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Password, :value => self[1]
    end

    # Who is
    node = command WhoIsNode do
      name 'whois', 'wi'
      args :user, :spaces_in_args => false
      change_args do |args|
        args[:user] = args[:user][0 .. -2] if args[:user].end_with?('?')
      end
    end
    return node if node

    # Where is
    node = command WhereIsNode do
      name 'whereis', 'wh', 'w'
      args :user, :spaces_in_args => false
      change_args do |args|
        args[:user] = args[:user][0 .. -2] if args[:user].end_with?('?')
      end
    end
    return node if node

    # Language
    node = command LanguageNode do
      name 'lang'
      name '_', :space_after_command => false
      args :name
    end
    return node if node

    # Unknown command
    if scan /^(#|\.)+\s*(\S+)\s*(?:.+?)?$/i
      trigger = self[1][0 ... 1]
      command = self[2]
      return UnknownCommandNode.new :trigger => trigger, :command => command
    end

    MessageNode.new options.merge(:body => string)
  end

  def parse_message_with_location(options = {})
    if scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+\.\d+\.\d+)\s*°?\s*(N|S)?(?:\s*\*?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+\.\d+\.\d+)\s*°?\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = location(* self[2].gsub(/\s/, '').split('.') + self[5].gsub(/\s/, '').split('.'))
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+\,\d+\,\d+)\s*°?\s*(N|S)?(?:\s*\*?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+\,\d+\,\d+)\s*°?\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = location(* self[2].gsub(/\s/, '').split(',') + self[5].gsub(/\s/, '').split(','))
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+\.\d+\.\d+\.\d+)\s*°?\s*(N|S)?(?:\s*\*?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+\.\d+\.\d+\.\d+)\s*°?\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = location(* self[2].gsub(/\s/, '').split('.') + self[5].gsub(/\s/, '').split('.'))
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+\,\d+\,\d+\,\d+)\s*°?\s*(N|S)?(?:\s*\*?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+\,\d+\,\d+\,\d+)\s*°?\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = location(* self[2].gsub(/\s/, '').split(',') + self[5].gsub(/\s/, '').split(','))
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)\s*°\s*(N|S)?(?:\s*(?:\*|,)?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)\s*°\s*(E|W)?\s*\*?\s*([^\s\d].+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = [self[2].gsub(/\s/, '').to_f, self[5].gsub(/\s/, '').to_f]
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)(?:\s*°\s*|\s+)(\d+)?(?:\s*'\s*|\s+)(\d+)?(?:\s*''\s*)?\s*(N|S)?(?:\s*(?:\*|,)?\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)(?:\s*°\s*|\s*)(\d+)?(?:\s*'\s*|\s*)(\d+)?(?:\s*''\s*)?\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[5] == 'S' ? -1 : 1
      sign1 = self[6] == 'W' || self[10] == 'W' ? -1 : 1
      loc = location(self[2].gsub(/\s/, ''), self[3], self[4], self[7].gsub(/\s/, ''), self[8], self[9])
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[11].try(:strip))
    elsif scan /^(?:at|l:)?\s*(N|S)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)\s*(N|S)?(?:\s*(?:\*|,)\s*|\s+)(E|W)?\s*((?:\+|\-)?\s*\d+(?:\.\d+)?)\s*(E|W)?\s*\*?\s*(.+?)?$/i
      sign0 = self[1] == 'S' || self[3] == 'S' ? -1 : 1
      sign1 = self[4] == 'W' || self[6] == 'W' ? -1 : 1
      loc = [self[2].gsub(/\s/, '').to_f, self[5].gsub(/\s/, '').to_f]
      loc[0] = loc[0] * sign0
      loc[1] = loc[1] * sign1
      MessageNode.new options.merge(:location => loc, :body => self[7].try(:strip))
    elsif scan /^(?:at|l:)\s+\/?(.+?)\/?\s*\*\s*([^\/]+)?$/i
      MessageNode.new options.merge(:location => self[1], :body => self[2].try(:strip))
    elsif scan /^(?:at|l:)\s+\/(.+?)\/\s*(!)?\s*(.+?)?$/i
      MessageNode.new options.merge(:location => self[1], :body => self[3].try(:strip), :blast => self[2] ? true : options[:blast])
    elsif scan /^\/?(.+?)\/?\s*\*\s*([^\/]+)?$/i
      MessageNode.new options.merge(:location => self[1], :body => self[2].try(:strip))
    elsif scan /^(?:(?:at|l:)\s+)?\s*\/([^\/]+)$/i
      pieces = self[1].split ' ', 2
      if pieces[1] && pieces[1].start_with?('!')
        options[:blast] = true
        pieces[1] = pieces[1][1 .. -1].strip
      end
      MessageNode.new options.merge(:location => pieces[0], :body => pieces[1])
    elsif scan /^(?:at|l:)\s+\/?(.+?)\/?$/i
      MessageNode.new options.merge(:location => self[1])
    elsif scan /^\/(.+?)\/\s*(!)?\s*(.+?)?$/i
      MessageNode.new options.merge(:location => self[1], :body => self[3].try(:strip), :blast => self[2] ? true : options[:blast])
    else
      nil
    end
  end

  def check_blast
    if scan /!\s*(.+?)$/i
      self.string = self[1]
      true
    else
      nil
    end
  end

  def check_numeric_location(string)
    if string =~ /^\s*(\d+(?:(?:\.|,)\d+)?)(?:\s+|\s*(?:,|\.|\*)\s*)(\d+(?:(?:\.|,)\d+)?)\s*$/
      location($1, $2)
    else
      string
    end
  end

  def new_signup(string, group = nil)
    SignupNode.new :display_name => string, :suggested_login => string.gsub(/\s/, ''), :group => group
  end

  def new_create_group(group_alias, pieces)
    options = {:alias => self[1], :public => false, :nochat => false}
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

  def location(*args)
    if args.length == 2
      args.map{|x| x.gsub(',', '.').to_f}
    elsif args.length == 6
      [deg(*args[0 .. 2]), deg(*args[3 .. 5])]
    elsif args.length == 8
      [deg(*args[0 .. 3]), deg(*args[4 .. 7])]
    end
  end

  def deg(*args)
    if args.length == 4
      args = [args[0], args[1], "#{args[2]}.#{args[3]}"]
    end
    first = args[0].to_f
    if first < 0
      -(-first + args[1].to_f / 60.0 + args[2].to_f / 3600.0)
    else
      first + args[1].to_f / 60.0 + args[2].to_f / 3600.0
    end
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
  attr_accessor :group
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
  attr_accessor :alias
  attr_accessor :public
  attr_accessor :nochat
  attr_accessor :name
end

class InviteNode < Node
  attr_accessor :group
  attr_accessor :users

  def fix_group
    if self.group
      group = Group.find_by_alias self.group
      if !group
        group = Group.find_by_alias self.users.first
        if group
          self.users = [self.group]
        else
          self.users.insert 0, self.group
        end
      end
    end
    group
  end
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
  attr_accessor :locations
  attr_accessor :mentions
  attr_accessor :tags
  attr_accessor :blast

  def location
    @locations.try(:first)
  end

  def location=(value)
    @locations = [value]
  end

  def target
    @targets.try(:first)
  end

  def target=(value)
    @targets = [value]
  end

  def second_target
    @targets.try(:second)
  end
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

class WhereIsNode < Node
  attr_accessor :user
end

class LanguageNode < Node
  attr_accessor :name
end

class PingNode < Node
  attr_accessor :text
end

class UnknownCommandNode < Node
  attr_accessor :trigger
  attr_accessor :command
  attr_accessor :suggestion
end

class Target
  attr_accessor :name
  attr_accessor :payload
  def initialize(name, payload = nil)
    @name = name
    @payload = payload
  end

  def ==(other)
    self.class == other.class && self.name == other.name
  end
end

class GroupTarget < Target
end

class UserTarget < Target
end

class UnknownTarget < Target
end
