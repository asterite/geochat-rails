class WhoIsNode < Node
  command do
    name 'whois', 'wi'
    args :user, :spaces_in_args => false
  end

  def after_scan
    self.user = self.user[0 .. -2] if self.user.end_with? '?'
  end

  def process
    user = User.find_by_login_or_mobile_number @user
    return reply T.user_does_not_exist(@user) unless user

    reply T.user_display_name_is(user)
  end
end
