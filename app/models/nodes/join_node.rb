class JoinNode < Node
  command do
    name 'join group'
    name 'join', 'joingroup'
    name 'j', :prefix => :required
    name '>', :space_after_command => false
    args :group, :spaces_in_args => false
  end

  def process
    return reply_not_logged_in unless current_user

    group = Group.find_by_alias @group
    if !group
      return reply_group_does_not_exist @group
    end

    if current_user.belongs_to group
      return reply T.you_already_belong_to_group(group)
    end

    if group.requires_aproval_to_join
      invite = Invite.find_by_group_and_user group, current_user
      if invite
        if invite.admin_accepted
          invite.destroy

          join current_user, group
        else
          invite.user_accepted = true
          invite.save!

          notify_join_request group
        end
      else
        current_user.request_join group
        notify_join_request group
      end
    else
      invite = Invite.find_by_group_and_user group, current_user
      if invite
        if invite.requestor
          send_message_to_user invite.requestor, T.user_has_accepted_your_invitation(current_user, group)
        end
        invite.destroy
      end

      join current_user, group
    end
  end
end
