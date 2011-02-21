class JoinNode < Node
  attr_accessor :group

  Command = ::Command.new self do
    name 'join group'
    name 'join', 'joingroup'
    name 'j', :prefix => :required
    name '>', :space_after_command => false
    args :group, :spaces_in_args => false
  end
end
