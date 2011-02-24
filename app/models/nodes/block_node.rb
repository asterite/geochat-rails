class BlockNode < Node
  command_after_group do
    name 'block'
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  def process
    return reply_not_logged_in unless current_user

    user = User.find_by_login_or_mobile_number @user
    if @group
      group = Group.find_by_alias @group
      if !group
        @user, @group = @group, @user
        group = Group.find_by_alias @group
        user = User.find_by_login_or_mobile_number @user
        if !group
          if user
            return reply_group_does_not_exist @group
          else
            return reply_group_does_not_exist(T.a_or_b(@group, @user))
          end
        end
      end
    end

    return reply_user_does_not_exist @user unless user

    if not group
      group = default_group({
        :no_default_group_message => T.you_must_specify_a_group_to_block(user)
      })
    end
    return unless group

    membership = current_user.membership_in group
    return reply T.you_cant_block_you_dont_belong_to_group(user, group) unless membership
    return reply T.you_cant_block_you_are_not_owner(user, group) unless membership.role == :owner
    return reply T.you_cant_block_yourself if user == current_user

    if group.block user
      reply T.user_blocked(user, group)
    else
      reply T.user_already_blocked(user, group)
    end
  end
end
