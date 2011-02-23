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

  def after_scan
    self.public = false
    self.nochat = false
    return unless self.options

    in_name = false
    name = nil
    self.options.split.each do |piece|
      case piece.downcase
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
    return reply_not_logged_in unless current_user
    return reply T.cannot_create_group_name_too_short(@alias) if @alias.length < 2
    return reply T.cannot_create_group_name_reserved(@alias) if @alias.command?
    return reply T.group_already_exists(@alias) if Group.find_by_alias @alias

    group = current_user.create_group :alias => @alias, :name => (@name || @alias), :chatroom => !@nochat
    reply T.group_created(@alias)
  end
end
