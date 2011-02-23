class OwnerNode < Node
  command_after_group do
    name 'owner group', :spaces_in_args => false
    name 'owner', 'ow', 'group owner', :spaces_in_args => false
    name '\$', :prefix => :none, :space_after_command => false, :spaces_in_args => false
    args :user, :spaces_in_args => false
    args :user, :group, :spaces_in_args => false
  end

  def after_scan
    self.group, self.user = self.user, self.group if self.group && self.group.integer?
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

    if !user
      return reply_user_does_not_exist @user
    end

    if not group
      group = default_group({
        :no_default_group_message => T.you_must_specify_a_group_to_set_owner(user)
      })
    end
    return unless group

    membership = user.membership_in group
    if !membership
      return reply T.user_does_not_belong_to_group(user, group)
    end

    if current_user.is_owner_of(group)
      if user == current_user
        return reply T.you_are_already_an_owner_of_group(group)
      end
    else
      if user == current_user
        return reply T.nice_try
      else
        return reply T.you_cant_set_owner_you_are_not_owner(user, group)
      end
    end

    if membership.role == :owner
      return reply T.user_already_an_owner(user, group)
    end

    membership.role = :owner
    membership.save!

    reply T.user_set_as_owner(user, group)
    send_message_to_user user, T.user_has_made_you_owner(current_user, group)
  end
end
