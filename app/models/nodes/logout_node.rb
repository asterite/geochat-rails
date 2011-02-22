class LogoutNode < Node
  command
  Help = T.help_logout

  Command = ::Command.new self do
    name 'logout', 'log out', 'logoff', 'log off', 'bye'
    name 'lo', :prefix => :required
    name '\)', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_channel

    current_channel.destroy

    reply T.device_removed_from_your_account(current_user)
  end
end
