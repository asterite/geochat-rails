class BlockNode < Node
  command_after_group do
    name 'block'
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  requires_user_to_be_logged_in

  include UserAndGroupNode

  def process
    user, group = solve_user_and_group :no_default_group_message => T.you_must_specify_a_group_to_block(@user)
    return unless user && group

    membership = current_user.membership_in group
    return reply T.you_cant_block_you_dont_belong_to_group(user, group) unless membership
    return reply T.you_cant_block_you_are_not_owner(user, group), :group => group unless membership.role == :owner
    return reply T.you_cant_block_yourself, :group => group if user == current_user

    if group.block user
      reply T.user_blocked(user, group), :group => group
    else
      reply T.user_already_blocked(user, group), :group => group
    end
  end
end
