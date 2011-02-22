class OffNode < Node
  command
  Help = "To stop receiving messages from this channel send: off"

  Command = ::Command.new self do
    name 'off', 'stop'
    name '-', :prefix => :none
  end

  def process
    return reply_not_logged_in unless current_user
    return if current_channel.status == :off

    current_channel.status = :off
    current_channel.save!

    reply "GeoChat Alerts. You sent '#{message[:body].strip}' and we have turned off updates on this #{current_channel.protocol_name}. Reply with START to turn back on. Questions email support@instedd.org."
  end
end
