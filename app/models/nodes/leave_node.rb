class LeaveNode < Node
  command
  Help = "To leave a group send: leave GROUP_ALIAS"

  attr_accessor :group

  Command = ::Command.new self do
    name 'leave group'
    name 'leave', 'leavegroup'
    name 'l', :prefix => :required
    name '<', :space_after_command => false
    args :group, :spaces_in_args => false
  end

  def process
    return reply_not_logged_in unless current_user

    group = Group.find_by_alias @group
    if !group
      return reply_group_does_not_exist(@group)
    end

    membership = current_user.membership_in(group)
    if !membership
      return reply "You can't leave group #{group.alias} because you don't belong to it."
    end

    if group.owners == [current_user]
      return reply "You can't leave group #{group.alias} because you are its only owner."
    end

    membership.destroy

    groups = current_user.groups
    case groups.count
    when 0
      reply "Good bye #{current_user.login} from your only group #{group.alias}. To join another group send: join groupalias"
    when 1
      reply "Good bye #{current_user.login} from group #{group.alias}. Now your default group is #{groups.first.alias}."
    else
      reply "Good bye #{current_user.login} from group #{group.alias}."
    end
  end
end

