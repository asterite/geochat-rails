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
    return reply_group_does_not_exist(@group) unless group

    membership = current_user.membership_in(group)
    return reply T.you_cant_leave_group_because_you_dont_belong_to_it(group) unless membership
    return reply T.you_cant_leave_group_because_you_are_its_only_owner(group) if group.owners == [current_user]

    membership.destroy

    reply T.good_bye_from_group(current_user, group)
  end
end

