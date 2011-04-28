class CreateNode < Node
  attr_accessor :public
  attr_accessor :nochat
  attr_accessor :name

  command do
    name 'create group'
    name 'creategroup', 'create', 'cg'
    name '\*', :prefix => :none, :space_after_command => false
    args :alias, :options
    args :alias
  end

  requires_user_to_be_logged_in

  def after_scan
    self.public = false
    self.nochat = false
    return unless self.options

    in_name = false
    name = nil
    self.options.split.each do |piece|
      case piece
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
    self.name = name.strip if name
    self.options = nil
  end

  def process
    check_can_create or return

    group = current_user.create_group :alias => @alias, :name => (@name || @alias), :chatroom => !@nochat
    reply T.group_created(@alias), :group => group
  end

  private

  def check_can_create
    reply T.cannot_create_group_name_too_short(@alias) and return false if @alias.length < 2
    reply T.cannot_create_group_name_reserved(@alias) and return false if @alias.command?
    reply T.group_already_exists(@alias) and return false if Group.find_by_alias @alias
    true
  end
end
