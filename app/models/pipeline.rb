class Pipeline

  attr_accessor :address2
  attr_accessor :protocol
  attr_accessor :message
  attr_accessor :messages
  attr_accessor :saved_message

  # Processes a message, which is a hash.
  #
  # :from => who sent the message (i.e.: sms://1234)
  # :body => the content of the message
  #
  # After processing a message you can see the results by
  # accessing Pipeline#messages, which is an array of hashes
  # with keys :to, :body and so on, which are messages
  # that were generated from the input message.
  #
  # Pipeline#saved_message will be a hash containing the description
  # of the message just sent (if it wasn't a command).
  def process(message = {})
    message = message.with_indifferent_access

    @address = message[:from]
    @protocol, @address2 = @address.split "://"
    @channel = nil
    @channel_initialized = false
    @message = message
    @messages = []
    @saved_message = nil

    node = Parser.parse(message[:body], self, :parse_signup_and_join => !current_user)

    turn_on_current_channel_if_needed node

    node.pipeline = self
    node.process
  end

  def get_target(name)
    if current_user
      group = current_user.groups.find_by_alias(name)
      return GroupTarget.new(name, :group => group) if group

      invite = Invite.joins(:group).where('user_id = ? and groups.alias = ?', current_user.id, name).first
      return GroupTarget.new(name, :group => invite.group, :invite => invite) if invite
    end

    nil
  end

  def join(user, group)
    user.join group
    send_message_to_user user, T.welcome_to_group(user, group)
  end

  def reply_not_logged_in
    reply T.you_are_not_signed_in
  end

  def reply_user_does_not_exist(user)
    reply T.user_does_not_exist(user)
  end

  def reply_group_does_not_exist(group)
    reply T.group_does_not_exist(group)
  end

  def reply_dont_belong_to_any_group
    reply T.you_dont_belong_to_any_group_yet
  end

  def reply(msg)
    send_message :to => @address, :body => msg
  end

  def notify_join_request(group)
    send_message_to_group_owners group, T.invitation_pending_for_approval(current_user, group)
    reply T.group_requires_approval(group)
  end

  def send_message_to_group(group, msg)
    group.users.includes(:channels).reject{|x| x.id == current_user.id}.each do |user|
      send_message_to_user_in_group user, group, msg
    end
  end

  def send_message_to_group_owners(group, msg, options = {})
    targets = group.owners
    targets.reject!{|x| x == options[:except]} if options[:except]
    targets.each do |user|
      send_message_to_user_in_group user, group, msg
    end
  end

  def send_message_to_user_in_group(user, group, msg)
    if group.id == user.default_group_id || user.memberships.count == 1
      send_message_to_user user, msg
    else
      send_message_to_user user, "[#{group.alias}] #{msg}"
    end
  end

  def send_message_to_user(user, msg)
    if user == current_user
      reply msg
    else
      user.active_channels.each do |channel|
        send_message_to_channel channel, msg
      end
    end
  end

  def send_message_to_channel(channel, msg)
    send_message :to => channel.full_address, :body => msg
  end

  def send_message(options = {})
    @messages << options
  end

  def turn_on_current_channel_if_needed(node)
    return if node.is_a?(OnNode) || node.is_a?(OffNode) || current_channel.try(:status) != :off

    current_channel.turn :on

    reply T.we_have_turned_on_updates_on_this_channel(current_channel)
  end

  def update_current_user_location_to(location)
    if location.is_a?(String)
      result = Geocoder.locate(location)
      if result
        coords = result[:lat], result[:lon]
        place = result[:location]
      else
        reply T.location_not_found(location)
        return false
      end

      short_url = Googl.shorten "http://maps.google.com/?q=#{CGI.escape place}"
    else
      place, coords = Geocoder.reverse(location), location
      short_url = Googl.shorten "http://maps.google.com/?q=#{coords.join ','}"
    end

    current_user.location = place
    current_user.coords = coords
    current_user.location_short_url = short_url
    current_user.save!

    reply T.location_successfuly_updated(place, current_user_location_info)

    true
  end

  def create_channel_for(user)
    Channel.create! :protocol => @protocol, :address => @address2, :user => user, :status => :on
  end

  def current_channel
    if !@channel_initialized
      @channel = Channel.find_by_protocol_and_address @protocol, @address2
      @channel_initialized = true
    end
    @channel
  end

  def channel=(chan)
    @channel = chan
    @channel_initialized = true
  end

  def current_user
    current_channel.try(:user)
  end

  def current_user_location_info
    user_location_info current_user
  end

  def user_location_info(user)
    str = "lat: #{user.lat}, lon: #{user.lon}"
    if user.location_short_url.present?
      str << ", url: #{user.location_short_url}"
    end
    str
  end

  def default_group(options = {})
    group = current_user.default_group
    return group if group

    groups = current_user.groups.to_a
    if groups.empty?
      reply_dont_belong_to_any_group
    elsif groups.length == 1
      return groups.first
    else
      reply options[:no_default_group_message]
    end

    nil
  end
end
