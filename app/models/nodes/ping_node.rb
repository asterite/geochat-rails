class PingNode < Node
  command

  attr_accessor :text

  Command = ::Command.new self do
    name 'ping'
    args :text, :optional => true
    help :no
  end

  def process
    if @text.present?
      reply "pong: #{@text} (received at #{Time.now.utc})"
    else
      reply "pong (received at #{Time.now.utc})"
    end
  end
end
