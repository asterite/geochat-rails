class BlockNode < Node
  command
  command_without_group

  attr_accessor :user
  attr_accessor :group

  Command = ::Command.new self do
    name 'block'
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end
end
