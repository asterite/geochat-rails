class Pipeline
  include ActionView::Helpers::DateHelper

  attr_accessor :address2
  attr_accessor :protocol
  attr_accessor :message
  attr_accessor :messages
  attr_accessor :saved_message

  # Processes a message, which is a hash.
  #
  # :from => who send the message (i.e.: sms://1234)
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
    if user.memberships.count > 1
      send_message_to_user user, "Welcome #{user.display_name} to #{group.alias}. Send '#{group.alias} Hello group!'"
    else
      send_message_to_user user, "Welcome #{user.display_name} to group #{group.alias}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
    end
  end

  def reply_not_logged_in
    reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
  end

  def reply_user_does_not_exist(user)
    reply "The user #{user} does not exist."
  end

  def reply_group_does_not_exist(group)
    reply "The group #{group} does not exist."
  end

  def reply_dont_belong_to_any_group
    reply "You don't belong to any group yet. To join a group send: join groupalias"
  end

  def reply(msg)
    send_message :to => @address, :body => msg
  end

  def notify_join_request(group)
    send_message_to_group_owners group, "An invitation is pending for approval. To approve it send: invite #{group.alias} #{current_user.login}"
    reply "Group #{group.alias} requires approval to join by an Administrator. We will let you know when you can start sending messages."
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

    current_channel.status = :on
    current_channel.save!

    reply "We have turned on updates on this #{current_channel.protocol_name}. Reply with STOP to turn off. Questions email support@instedd.org."
  end

  def update_current_user_location_to(location)
    if location.is_a?(String)
      result = Geocoder.locate(location)
      if result
        coords = result[:lat], result[:lon]
        place = result[:location]
      else
        reply "The location '#{location}' could not be found on the map."
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

    reply "Your location was successfully updated to #{place} (#{current_user_location_info})"

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
