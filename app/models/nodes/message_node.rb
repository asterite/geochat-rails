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
    @text_to_send = @body
    @text_to_save = @body
    @location_info = nil

    (validate_targets or return) if has_targets?
    validate_group_enabled or return
    validate_default_group or return
    validate_group_enabled or return # Needed again because the last line might have changed the group
    (validate_send_to_users_via_group or return) if has_target_users?
    (validate_invite or return) if has_invite?
    (validate_can_join_group or return) unless belongs_to_group?

    process_location if has_location?

    send_to_external_service if must_send_to_external_service?
    return if external_service_said_stop?

    send_messages
    save_message
  end

  private

  def has_targets?
    self.target.present?
  end

  def validate_targets
    @users = []

    validate_first_target
    validate_other_targets

    if @group || @users.present?
      true
    else
      reply T.group_does_not_exist(self.target.name)
      false
    end
  end

  def validate_first_target
    if self.target.is_a?(UnknownTarget)
      @group = Group.find_by_alias self.target.name
      user = User.find_by_login_or_mobile_number(self.target.name) and @users << user unless @group
    elsif self.target.is_a?(GroupTarget)
      @group = self.target.payload[:group]
      @explicit_group = true
      @invites = self.target.payload[:invites]
    end
  end

  def validate_other_targets
    @targets[1 .. -1].each do |target|
      if @group
        validate_target_is_a_mobile_number target.name, @group
      elsif @users.present?
        @group = Group.find_by_alias target.name
        if @group
          @explicit_group = true
        else
          validate_target_is_a_mobile_number target.name
        end
      end
    end
  end

  def validate_target_is_a_mobile_number(target, group = nil)
    user = User.find_by_login_or_mobile_number target
    if user
      @users << user
    else
      reply T.user_does_not_exist(target), :group => group
    end
  end

  def validate_group_enabled
    if @group && !@group.enabled?
      reply T.cant_send_messages_to_disabled_group(@group)
      false
    else
      true
    end
  end

  def has_target_users?
    @users.present?
  end

  def validate_send_to_users_via_group
    @users.each do |user|
      if @explicit_group && !user.belongs_to?(@group)
        reply T.cant_send_message_to_user_via_group_does_not_belong(user, @group), :group => @group
        return false
      elsif !current_user.shares_a_common_group_with?(user)
        reply T.cant_send_message_to_user_no_common_group(user)
        return false
      end
    end
    true
  end

  def validate_default_group
    if !@group
      @group = default_group :no_default_group_message => T.you_dont_have_a_default_group_prefix_messages
    end
    @group
  end

  def has_invite?
    @invites.present?
  end

  def validate_invite
    if @invites.any?(&:admin_accepted?) || !@group.requires_approval_to_join?
      join_and_welcome current_user, @group
      @invites.each &:destroy
    else
      reply T.cant_send_message_to_group_invitation_not_approved(@group)
      return false
    end
    true
  end

  def belongs_to_group?
    @membership = current_user.membership_in @group
  end

  def validate_can_join_group
    if @group.requires_approval_to_join
      reply T.cant_send_message_to_group_not_a_member(@group)
      false
    else
      join_and_welcome current_user, @group
      true
    end
  end

  def has_location?
    location.present?
  end

  def process_location
    location_update_result = update_current_user_location_to self.location, @group
    if location_update_result
      @location_info = true
    else
      @text_to_send = message[:body]
    end

    if @text_to_save.blank?
      if location_update_result.is_a? CustomLocation
        @text_to_save = T.at_place(location_update_result.location)
      else
        @text_to_save = T.at_place(self.location.is_a?(String) ? self.location : self.location.join(', '))
      end
    end
  end

  def must_send_to_external_service?
    @group.external_service_url.present? && @text_to_send.present? && (@group.external_service_prefix.blank? || @text_to_send.start_with?(@group.external_service_prefix))
  end

  def send_to_external_service
    response = post_to_external_service
    case response[:action]
    when 'stop'
      @external_service_said_stop = true
    when 'continue'
      if response[:replace_with].present?
        @text_to_send = @text_to_save = response[:replace_with]
      elsif response[:replace].present?
        @text_to_send = @text_to_save = response[:body]
      end
    when 'reply'
      reply response[:body], :group => @group
      @external_service_said_stop = true
    when 'reply-and-continue'
      reply response[:body], :group => @group
      if response[:replace_with].present?
        @text_to_send = @text_to_save = response[:replace_with]
      end
    end
  end

  def external_service_said_stop?
    @external_service_said_stop
  end

  def post_to_external_service
    request_body = @text_to_send
    request_body = request_body[@group.external_service_prefix.length .. -1].strip if @group.external_service_prefix.present?

    query = {:from => message[:from], :to => message[:to], :sender => current_user.login}
    query[:lat], query[:lon] = current_user.coords if current_user.location_known?
    response = HTTParty.post("#{@group.external_service_url}?#{query.to_query}", :body => request_body)
    headers = response.headers
    {
      :action => headers['x-geochat-action'],
      :replace => headers['x-geochat-replace'],
      :replace_with => headers['x-geochat-replacewith'],
      :body => response.body
    }
  end

  def send_messages
    if @users.present?
      @users.each do |user|
        others = @users.reject{|x| x == user}
        send_message_to_user user, @text_to_send, :sender => current_user, :group => @group, :private => true, :receivers => others, :location => @location_info, :dont_translate => true
      end
    else
      targets = @blast ? :all : @group.message_targets(@membership)
      case targets
      when :admins
        send_message_to_group_admins @group, @text_to_send, :sender => current_user, :location => @location_info, :dont_translate => true
      when :all
      send_message_to_group @group, @text_to_send, :sender => current_user, :location => @location_info, :dont_translate => true
      end
    end
  end

  def save_message
    options = {}
    options[:receivers] = @users.map(&:id) if @users.present?
    current_user.create_message_for_group @group, @text_to_save, options
  end
end
