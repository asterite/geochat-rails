class MyNode < Node
  attr_accessor :key
  attr_accessor :value

  Groups = :groups
  Group = :group
  Name = :name
  Email = :email
  Login = :login
  Password = :password
  Number = :number
  Location = :location

  command do |strscan|
    if strscan.scan /^\.*\s*my\s*$/i
      return HelpNode.new :node => MyNode
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(help|\?)\s*$/i
      return HelpNode.new :node => MyNode
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)groups\s*$/i
      return MyNode.new :key => MyNode::Groups
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(?:group|g)\s*$/i
      return MyNode.new :key => MyNode::Group
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(?:group|g)\s+(?:@\s*)?(\S+)\s*$/i
      return MyNode.new :key => MyNode::Group, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)name\s*$/i
      return MyNode.new :key => MyNode::Name
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)name\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Name, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)email\s*$/i
      return MyNode.new :key => MyNode::Email
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)email\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Email, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*$/i
      return MyNode.new :key => MyNode::Number
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)(number|phone|phonenumber|phone\s+number|mobile|mobilenumber|mobile\s+number)\s*(.+?)\s*$/i
      return MyNode.new :key => MyNode::Number, :value => strscan[1].strip
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)location\s*$/i
      return MyNode.new :key => MyNode::Location
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)location\s+(.+?)\s*$/i
      return MyNode.new :key => MyNode::Location, :value => strscan[1].strip.to_location
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)login\s*$/i
      return MyNode.new :key => MyNode::Login
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)login\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Login, :value => strscan[1]
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)password\s*$/i
      return MyNode.new :key => MyNode::Password
    elsif strscan.scan /^\.*\s*my(?:\s+|_*)password\s+(\S+)\s*$/i
      return MyNode.new :key => MyNode::Password, :value => strscan[1]
    end
  end

  def self.names
    [{:regex_end => /^\s*my\s*$/i}]
  end

  def process
    return reply_not_logged_in unless current_user

    if @value
      send "process_my_#{@key}=", @value
    else
      send "process_my_#{@key}"
    end
  end

  def process_my_login
    reply T.your_login_is(current_user.login)
  end

  def process_my_login=(value)
    new_login = value.gsub(' ', '')
    if ::User.find_by_login(new_login)
      return reply T.login_taken(new_login)
    end

    current_user.login = value.gsub(' ', '')
    current_user.save!

    reply T.your_new_login_is(current_user.login)
  end

  def process_my_name
    reply T.your_display_name_is(current_user.display_name)
  end

  def process_my_name=(value)
    current_user.display_name = value
    current_user.save!

    reply T.your_new_display_name_is(current_user.display_name)
  end

  def process_my_password
    reply T.forgot_your_password?
  end

  def process_my_password=(value)
    current_user.password = value
    current_user.save!

    reply T.your_new_password_is(value)
  end

  def process_my_number
    sms_channel = current_user.sms_channel
    if sms_channel
      reply T.your_phone_number_is(sms_channel.address)
    else
      reply T.you_dont_have_a_phone_number_configured
    end
  end

  def process_my_number=(value)
    reply T.you_cant_change_your_phone_number
  end

  def process_my_email
    email_channel = current_user.email_channel
    if email_channel
      reply T.your_email_is(email_channel.address)
    else
      reply T.you_dont_have_an_email
    end
  end

  def process_my_email=(value)
    reply T.you_cant_change_your_email
  end

  def process_my_groups
    groups = current_user.groups.map(&:alias).sort
    case groups.count
    when 0
      return reply_dont_belong_to_any_group
    when 1
      reply T.your_only_group_is(groups.first)
    else
      reply T.your_groups_are(groups)
    end
  end

  def process_my_group
    group = current_user.default_group || default_group({
      :no_default_group_message => T.you_dont_have_a_default_group_choose_one
    })
    return unless group

    reply T.your_default_group_is(group)
  end

  def process_my_group=(value)
    group = ::Group.find_by_alias value
    if !group
      return reply_group_does_not_exist value
    end

    if !current_user.belongs_to(group)
      return reply T.you_cant_set_group_as_default_group_dont_belong(group)
    end

    current_user.default_group_id = group.id
    current_user.save!

    return reply T.your_new_default_group_is(group.alias)
  end

  def process_my_location
    if !current_user.location_known?
      return reply T.you_never_reported_your_location
    end

    return reply T.you_said_you_was_in(current_user.location, current_user_location_info, current_user.location_reported_at)
  end

  def process_my_location=(value)
    update_current_user_location_to value
  end
end
