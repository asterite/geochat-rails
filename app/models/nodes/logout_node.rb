class LogoutNode < Node
  command do
    name 'logout', 'log out', 'logoff', 'log off', 'bye'
    name 'lo', :prefix => :required
    name '\)', :prefix => :none
  end

  requires_user_to_be_logged_in

  def process
    current_channel.destroy

    reply T.device_removed_from_your_account(current_user)
  end
end
