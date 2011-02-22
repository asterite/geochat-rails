class WhoIsNode < Node
  command
  Help = T.help_whois

  attr_accessor :user

  Command = ::Command.new self do
    name 'whois', 'wi'
    args :user, :spaces_in_args => false
  end

  def after_scan
    self.user = self.user[0 .. -2] if self.user.end_with? '?'
  end

  def process
    user = User.find_by_login_or_mobile_number @user
    if !user
      return reply_user_does_not_exist @user
    end

    reply T.user_display_name_is(user)
  end
end
