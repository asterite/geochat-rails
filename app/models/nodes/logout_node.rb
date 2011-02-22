class LogoutNode < Node
  command
  Help = "To logout from GeoChat send: logout"

  Command = ::Command.new self do
    name 'logout', 'log out', 'logoff', 'log off', 'bye'
    name 'lo', :prefix => :required
    name '\)', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_channel

    current_channel.destroy

    reply "#{current_user.display_name}, this device has been removed from your account."
  end
end
