class WhereIsNode < Node
  command
  Help = "To find out the location of a user send: .whereis USER_LOGIN"

  attr_accessor :user

  Command = ::Command.new self do
    name 'whereis', 'wh', 'w'
    args :user, :spaces_in_args => false
  end

  def after_scan
    self.user = self.user[0 .. -2] if self.user.end_with? '?'
  end

  def process
    return reply_not_logged_in unless current_user

    user = User.find_by_login_or_mobile_number @user
    if !user
      return reply_user_does_not_exist @user
    end

    if user != current_user && !current_user.shares_a_common_group_with(user)
      return reply "You can't see the location of #{user.login} because you don't share a common group."
    end

    if !user.location_known?
      return reply "#{user.login} never reported his/her location."
    end

    reply "#{user.login} said he/she was in #{user.location} (#{user_location_info user}) #{time_ago_in_words user.location_reported_at} ago."
  end
end
