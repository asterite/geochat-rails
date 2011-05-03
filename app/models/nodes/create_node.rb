class CreateNode < Node
  attr_accessor :public
  attr_accessor :kind
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
    @public = false
    @kind = :chatroom
    return unless @options

    in_name = false
    name = nil
    @options.split.each do |piece|
      case piece
      when 'name'
        in_name = true
        name = ''
      when 'chat', 'chatroom'
        @kind = :chatroom
        in_name = false
      when 'alert', 'alerts'
        @kind = @kind == :reports ? :reports_and_alerts : :alerts
        in_name = false
      when 'report', 'reports'
        @kind = @kind == :alerts ? :reports_and_alerts : :reports
        in_name = false
      when 'messaging'
        @kind = :messaging
        in_name = false
      when 'public', 'nohide', 'visible'
        self.public = true
        in_name = false
      when 'hide', 'hidden', 'private'
        in_name = false
      else
        if name
          name << piece
          name << ' '
        end
      end
    end
    @name = name.strip if name
    @options = nil
  end

  def process
    return reply T.cannot_create_group_name_too_short(@alias) if @alias.length < 2
    return reply T.cannot_create_group_name_reserved(@alias) if @alias.command?
    return reply T.group_already_exists(@alias) if Group.find_by_alias @alias

    group = current_user.create_group :alias => @alias, :name => (@name || @alias), :kind => @kind, :hidden => !@public
    reply T.group_created(@alias), :group => group
  end
end
