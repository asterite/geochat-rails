class OnNode < Node
  command do
    name 'on', 'start'
    name '\!', :prefix => :none
  end

  requires_user_to_be_logged_in

  def process
    current_channel.turn :on

    reply T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel(message[:body].strip, current_channel)
  end
end
