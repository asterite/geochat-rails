class MessageNode < Node
  attr_accessor :body
  attr_accessor :targets
  attr_accessor :locations
  attr_accessor :mentions
  attr_accessor :tags
  attr_accessor :blast

  def initialize(attributes = {})
    super

    return unless self.body

    check_mentions
    check_tags
    check_locations
  end

  def location
    @locations.try(:first)
  end

  def location=(value)
    @locations = [value]
  end

  def target
    @targets.try(:first)
  end

  def target=(value)
    @targets = [value]
  end

  def second_target
    @targets.try(:second)
  end

  def check_mentions
    self.body.scan /\s+@\s*(\S+)/ do |match|
      self.mentions ||= []
      self.mentions << match.first
    end
  end

  def check_tags
    self.body.scan /#\s*(\S+)/ do |match|
      self.tags ||= []
      self.tags << match.first
    end
  end

  def check_locations
    self.body.scan /\s+\/[^\/]+\/|\s+\/\S+/ do |match|
      match = match.strip
      match = match[1 .. -1] if match.start_with?('/')
      ['/', ',', '.', ';'].each do |char|
        match = match[0 .. -2] if match.end_with?(char)
      end
      if match.present?
        self.locations ||= []
        self.locations << match.to_location
      end
    end
  end

  def process
    if !current_user
      return reply 'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
    end

    if self.target.present?
      if self.target.is_a?(UnknownTarget)
        group = Group.find_by_alias self.target.name
        user = User.find_by_login_or_mobile_number self.target.name unless group
      elsif self.target.is_a?(GroupTarget)
        group = self.target.payload[:group]
        explicit_group = true
        invite = self.target.payload[:invite]
      end

      if self.second_target
        if group
          user = User.find_by_login_or_mobile_number self.second_target.name
        elsif user
          group = Group.find_by_alias self.second_target.name
          explicit_group = true
        end
      end

      if !group && !user
        return reply_group_does_not_exist self.target.name
      end
    end

    # This is needed here and also bellow. Here because if there is an explicit
    # target group we don't want to allow sending even location updates.
    # Below because if an explicit group is not found then it is the default group
    # and it might be disabled.
    if group && !group.enabled
      return reply "You can't send messages to #{group.alias} because it is disabled."
    end

    text_to_send = @body
    text_to_save = @body

    if self.location.present?
      if update_current_user_location_to self.location
        if text_to_send.blank?
          text_to_send = "at #{current_user.location} (#{current_user_location_info})"
        else
          text_to_send = "#{text_to_send} (at #{current_user.location}, #{current_user_location_info})"
        end
      else
        text_to_send = message[:body]
      end

      if text_to_save.blank?
        if self.location.is_a?(String)
          text_to_save = "at #{self.location}"
        else
          text_to_save = "at #{self.location.join ', '}"
        end
      end
    end

    if not group
      group = default_group({
        :no_default_group_message => "You don't have a default group so prefix messages with a group (for example: groupalias Hello!) or set your default group with: .my group groupalias"
      })
    end
    return unless group

    if group && !group.enabled
      return reply "You can't send messages to #{group.alias} because it is disabled."
    end

    if user
      if explicit_group && !user.belongs_to(group)
        return reply "You can't send a message to user #{user.login} via group #{group.alias} because he/she does not belong to it"
      elsif !current_user.shares_a_common_group_with(user)
        return reply "You can't send a message to user #{user.login} because you don't share a common group"
      end
    end

    if invite
      if invite.admin_accepted || !group.requires_aproval_to_join
        join current_user, group
        invite.destroy
      else
        return reply "You can not send messages to the group #{group.alias} as your invitation has not yet been approved by an admin."
      end
    end

    if !current_user.belongs_to(group)
      if group.requires_aproval_to_join
        return reply "You can not send messages to the group #{group.alias} because you are not a member or the group requires approval to join. To request an invitation send: join #{group.alias}"
      else
        join current_user, group
      end
    end

    if user
      send_message_to_user_in_group user, group, "#{current_user.login} only to you: #{text_to_send}"
      if group.forward_owners
        send_message_to_group_owners group, "#{current_user.login} only to #{user.login}: #{text_to_send}", :except => user
      end
    elsif group.chatroom || @blast
      send_message_to_group group, "#{current_user.login}: #{text_to_send}"
    elsif group.forward_owners
      send_message_to_group_owners group, "#{current_user.login}: #{text_to_send}"
    end

    self.saved_message = {
      :sender => current_user,
      :group => group,
      :receiver => user,
      :text => text_to_save,
      :lat => current_user.lat,
      :lon => current_user.lon,
      :location => current_user.location,
      :location_short_url => current_user.location_short_url
    }
  end
end
