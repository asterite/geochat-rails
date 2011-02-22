class OnNode < Node
  command
  Help = "To start receiving messages from this channel send: on"

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

    reply "You sent '#{message[:body].strip}' and we have turned on updates on this #{current_channel.protocol_name}. Reply with STOP to turn off. Questions email support@instedd.org."
  end
end
