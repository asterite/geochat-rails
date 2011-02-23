class LeaveNode < Node
  command do
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
      return reply T.you_cant_leave_group_because_you_dont_belong_to_it(group)
    end

    if group.owners == [current_user]
      return reply T.you_cant_leave_group_because_you_are_its_only_owner(group)
    end

    membership.destroy

    reply T.good_bye_from_group(current_user, group)
  end
end

