class OwnerNode < Node
  command
  command_without_group
  Help = "To make a user owner of a group send: owner GROUP_ALIAS USER_LOGIN"

  attr_accessor :user
  attr_accessor :group

  Command = ::Command.new self do
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
            return reply_group_does_not_exist("#{@group} or #{@user}")
          end
        end
      end
    end

    if !user
      return reply_user_does_not_exist @user
    end

    if not group
      group = default_group({
        :no_default_group_message => "You must specify a group to set #{user.login} as an owner, or set a default group.",
      })
    end
    return unless group

    membership = user.membership_in group
    if !membership
      return reply "The user #{user.login} does not belong to group #{group.alias}."
    end

    if current_user.is_owner_of(group)
      if user == current_user
        return reply "You are already an owner of group #{group.alias}."
      end
    else
      if user == current_user
        return reply "Nice try :-P"
      else
        return reply "You can't set #{user.login} as an owner of #{group.alias} because you are not an owner."
      end
    end

    if membership.role == :owner
      return reply "#{user.login} is already an owner in group Group1."
    end

    membership.role = :owner
    membership.save!

    reply "The user #{user.login} was successfully set as owner of group #{group.alias}."
    send_message_to_user user, "#{current_user.login} has made you owner of group #{group.alias}."
  end
end
