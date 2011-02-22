class WhoIsNode < Node
  command
  Help = "To find out the display name of a user send: .whois USER_LOGIN"

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

    reply "#{user.login}'s display name is: #{user.display_name}."
  end
end
