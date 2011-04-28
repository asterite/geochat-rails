module UserAndGroupNode
  def solve_user_and_group(options = {})
    user = User.find_by_login_or_mobile_number @user
    if @group
      group = Group.find_by_alias @group
      if !group
        @user, @group = @group, @user
        group = Group.find_by_alias @group
        user = User.find_by_login_or_mobile_number @user
        if !group
          if user
            reply T.group_does_not_exist(@group)
          else
            reply T.group_does_not_exist(T.a_or_b(@group, @user))
          end
          return false
        end
      end
    end

    group = default_group(options) unless group

    if !user
      if group
        reply T.user_does_not_exist(@user), :group => group
      else
        reply T.user_does_not_exist(@user)
      end
      return false
    end

    if group
      @user, @group = user, group
      true
    else
      false
    end
  end
end
