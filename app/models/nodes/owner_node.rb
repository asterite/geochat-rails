class OwnerNode < Node
  attr_accessor :user
  attr_accessor :group

  Command = ::Command.new self do
    name 'owner group', :spaces_in_args => false
    name 'owner', 'ow', 'group owner', :spaces_in_args => false
    name '\$', :prefix => :none, :space_after_command => false, :spaces_in_args => false
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  def after_scan
    self.group, self.user = self.user, self.group if self.group && self.group.integer?
  end
end
