class LeaveNode < Node
  command

  attr_accessor :group

  Command = ::Command.new self do
    name 'leave group'
    name 'leave', 'leavegroup'
    name 'l', :prefix => :required
    name '<', :space_after_command => false
    args :group, :spaces_in_args => false
  end
end

