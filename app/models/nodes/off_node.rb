class OffNode < Node
  command do
    name 'off', 'stop'
    name '-', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_user

    if current_channel.turn :off
      reply T.you_sent_off_and_we_have_turned_off_channel(message[:body].strip, current_channel)
    end
  end
end
