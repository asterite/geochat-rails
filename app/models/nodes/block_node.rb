class BlockNode < Node
  command
  command_without_group
  Help = T.help_block

  attr_accessor :user
  attr_accessor :group

  Command = ::Command.new self do
    name 'block'
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  def process
    reply 'Block is not yet implemented.'
  end
end
