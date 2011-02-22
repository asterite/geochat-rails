class OnNode < Node
  command
  Help = T.help_on

  Command = ::Command.new self do
    name 'on', 'start'
    name '\!', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_user

    if current_channel.status != :on
      current_channel.status = :on
      current_channel.save!
    end

    reply T.you_sent_on_and_we_have_turned_on_udpated_on_this_channel(message[:body].strip, current_channel)
  end
end
