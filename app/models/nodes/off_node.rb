class OffNode < Node
  command
  Help = T.help_off

  Command = ::Command.new self do
    name 'off', 'stop'
    name '-', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_user
    return if current_channel.status == :off

    current_channel.status = :off
    current_channel.save!

    reply T.you_sent_off_and_we_have_turned_off_channel(message[:body].strip, current_channel)
  end
end
