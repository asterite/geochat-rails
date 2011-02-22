class CreateNode < Node
  command

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
end
