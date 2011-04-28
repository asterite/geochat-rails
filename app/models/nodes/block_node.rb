class BlockNode < Node
  command_after_group do
    name 'block'
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  requires_user_to_be_logged_in

  include UserAndGroupNode

  def process
    solve_user_and_group :no_default_group_message => T.you_must_specify_a_group_to_block(@user) or return
    check_valid_membership or return

    if @group.block @user
      reply T.user_blocked(@user, @group), :group => @group
    else
      reply T.user_already_blocked(@user, @group), :group => @group
    end
  end

  private

  def check_valid_membership
    membership = current_user.membership_in @group
    reply T.you_cant_block_you_dont_belong_to_group(@user, @group) and return false unless membership
    reply T.you_cant_block_you_are_not_owner(@user, @group), :group => @group and return false unless membership.role == :owner
    reply T.you_cant_block_yourself, :group => @group and return false if @user == current_user
    return true
  end
end
