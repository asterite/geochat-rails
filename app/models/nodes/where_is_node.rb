class WhereIsNode < Node
  command do
    name 'whereis', 'wh', 'w'
    args :user, :spaces_in_args => false
  end

  def after_scan
    self.user = self.user[0 .. -2] if self.user.end_with? '?'
  end

  def process
    return reply_not_logged_in unless current_user

    user = User.find_by_login_or_mobile_number @user
    return reply_user_does_not_exist @user unless user

    if user != current_user && !current_user.shares_a_common_group_with(user)
      return reply T.you_cant_see_location_no_common_group(user)
    end

    if user.location_known?
      reply T.user_said_she_was_in(user, user.location, user_location_info(user), user.location_reported_at)
    else
      reply T.user_never_reported_location(user)
    end
  end
end
