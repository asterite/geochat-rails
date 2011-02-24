class OffNode < Node
  command do
    name 'off', 'stop'
    name '-', :prefix => :none
  end

  requires_user_to_be_logged_in

  def process
    if current_channel.turn :off
      reply T.you_sent_off_and_we_have_turned_off_channel(message[:body].strip, current_channel)
    end
  end
end
