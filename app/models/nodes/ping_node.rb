class PingNode < Node
  command do
    name 'ping'
    args :text, :optional => true
  end

  def process
    received = T.received_at(Time.now.utc)
    if @text.present?
      reply "pong: #{@text} (#{received})"
    else
      reply "pong (#{received})"
    end
  end
end
