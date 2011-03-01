class MessageNode < Node
  attr_accessor :body
  attr_accessor :targets
  attr_accessor :locations
  attr_accessor :mentions
  attr_accessor :tags
  attr_accessor :blast

  requires_user_to_be_logged_in

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
    users = []

    if self.target.present?
      if self.target.is_a?(UnknownTarget)
        group = Group.find_by_alias self.target.name
        if not group
          user = User.find_by_login_or_mobile_number self.target.name
          users << user if user
        end
      elsif self.target.is_a?(GroupTarget)
        group = self.target.payload[:group]
        explicit_group = true
        invite = self.target.payload[:invite]
      end

      @targets[1 .. -1].each do |target|
        if group
          user = User.find_by_login_or_mobile_number target.name
          if user
            users << user
          else
            reply T.user_does_not_exist(target.name)
          end
        elsif users.present?
          group = Group.find_by_alias target.name
          if group
            explicit_group = true
          else
            user = User.find_by_login_or_mobile_number target.name
            if user
              users << user
            else
              reply T.user_does_not_exist(target.name)
            end
          end
        end
      end

      return reply T.group_does_not_exist(self.target.name) unless group || users.present?
    end

    # This is needed here and also bellow. Here because if there is an explicit
    # target group we don't want to allow sending even location updates.
    # Below because if an explicit group is not found then it is the default group
    # and it might be disabled.
    return reply T.cant_send_messages_to_disabled_group(group) if group && !group.enabled

    if not group
      group = default_group({
        :no_default_group_message => T.you_dont_have_a_default_group_prefix_messages
      })

      # This saves us a query because we know the group came from the user memberships
      current_user_belongs_to_group = true
    end
    return unless group

    return reply T.cant_send_messages_to_disabled_group(group) if group && !group.enabled

    users.each do |user|
      if explicit_group && !user.belongs_to?(group)
        return reply T.cant_send_message_to_user_via_group_does_not_belong(user, group)
      elsif !current_user.shares_a_common_group_with(user)
        return reply T.cant_send_message_to_user_no_common_group(user)
      end
    end

    if invite
      if invite.admin_accepted || !group.requires_aproval_to_join
        join_and_welcome current_user, group
        invite.destroy
      else
        return reply T.cant_send_message_to_group_invitation_not_approved(group)
      end
    end

    if !current_user_belongs_to_group && !current_user.belongs_to?(group)
      if group.requires_aproval_to_join
        return reply T.cant_send_message_to_group_not_a_member(group)
      else
        join_and_welcome current_user, group
      end
    end

    text_to_send = @body
    text_to_save = @body
    location_info = nil

    if self.location.present?
      if update_current_user_location_to self.location
        location_info = true
      else
        text_to_send = message[:body]
      end

      if text_to_save.blank?
        text_to_save = T.at_place(self.location.is_a?(String) ? self.location : self.location.join(', '))
      end
    end

    if users.present?
      users.each do |user|
        others = users.reject{|x| x == user}
        send_message_to_user user, text_to_send, :sender => current_user, :group => group, :private => true, :receivers => others, :location => location_info, :dont_translate => true
      end
      if group.forward_owners
        send_message_to_group_owners group, text_to_send, :sender => current_user, :receivers => users, :location => location_info, :except => users, :dont_translate => true
      end
    elsif group.chatroom || @blast
      send_message_to_group group, text_to_send, :sender => current_user, :location => location_info, :dont_translate => true
    elsif group.forward_owners
      send_message_to_group_owners group, text_to_send, :sender => current_user, :location => location_info, :dont_translate => true
    end

    # Save the message
    saved_message = {
      :sender => current_user,
      :group => group,
      :text => text_to_save,
      :lat => current_user.lat,
      :lon => current_user.lon,
      :location => current_user.location,
      :location_short_url => current_user.location_short_url
    }
    saved_message[:receivers] = users.map(&:id) if users.present?
    Message.create_from_hash saved_message
  end
end
