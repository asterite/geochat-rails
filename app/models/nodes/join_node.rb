class JoinNode < Node
  command do
    name 'join group'
    name 'join', 'joingroup'
    name 'j', :prefix => :required
    name '>', :space_after_command => false
    args :group, :spaces_in_args => false
  end

  requires_user_to_be_logged_in

  def process
    group = Group.find_by_alias @group
    return reply T.group_does_not_exist(@group) unless group

    return reply T.you_already_belong_to_group(group) if current_user.belongs_to? group

    # Get all the invites for this user
    invites = Invite.find_all_by_group_id_and_user_id group, current_user

    # If it doesn't require approval or if any invite is already approved by an admin,
    # just join the group, notify the requestors and destroy the invites
    if !group.requires_approval_to_join || invites.any?{|x| x.admin_accepted}
      join_and_welcome current_user, group

      invites.each do |invite|
        send_message_to_user invite.requestor, :user_has_accepted_your_invitation, :args => [current_user, group] if invite.requestor
        invite.destroy
      end
      return
    end

    # If it requires approval...

    # If no invite exists yet, request join
    if invites.empty?
      current_user.request_join group
    else
      # Otherwise, mark each invite as accepted by the user
      # (so when an admin approves it we can join the user)
      invites.each do |invite|
        invite.user_accepted = true
        invite.save!
      end
    end

    notify_join_request group
  end
end
