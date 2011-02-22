class CreateNode < Node
  command
  Help = "To create a group send: create GROUP_ALIAS"

  attr_accessor :alias
  attr_accessor :public
  attr_accessor :nochat
  attr_accessor :name
  attr_accessor :options # Just used for parsing

  Command = ::Command.new self do
    name 'create group'
    name 'creategroup', 'create', 'cg'
    name '\*', :prefix => :none, :space_after_command => false
    args :alias, :options
    args :alias
  end

  def after_scan
    self.public = false
    self.nochat = false
    if self.options
      pieces = self.options.split
      in_name = false
      name = nil
      pieces.each do |piece|
        down = piece.downcase
        case down
        when 'name'
          in_name = true
          name = ''
        when 'nochat', 'alert'
          self.nochat = true
          in_name = false
        when 'public', 'nohide', 'visible'
          self.public = true
          in_name = false
        when 'chat', 'chatroom', 'hide', 'private'
          in_name = false
        else
          name << piece
          name << ' '
        end
      end
    end
    self.name = name.strip if name
    self.options = nil
  end

  def process
    return reply_not_logged_in unless current_user

    if @alias.length < 2
      return reply "You cannot create a group named '#{@alias}' because it is too short (minimum is 2 characters)."
    end

    if @alias.command?
      return reply "You cannot create a group named '#{@alias}' because it is a reserved name."
    end

    if Group.find_by_alias @alias
      return reply "The group #{@alias} already exists. Please specify another alias."
    end

    group = current_user.create_group :alias => @alias, :name => (@name || @alias), :chatroom => !@nochat

    reply "Group '#{group.alias}' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: #{group.alias} +PHONE_NUMBER"
  end
end
