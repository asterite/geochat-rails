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

    if !user
      reply T.user_does_not_exist(@user)
      return false
    end

    group = default_group(options) unless group

    group ? [user, group] : false
  end
end
