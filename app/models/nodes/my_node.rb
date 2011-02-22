class MyNode < Node
  command
  Help = "To change your settings send: .my OPTION or .my OPTION VALUE. Options: login, password, name, email, phone, location, group, groups"

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

  def self.scan(strscan)
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
    reply "Your login is: #{current_user.login}"
  end

  def process_my_login=(value)
    new_login = value.gsub(' ', '')
    if ::User.find_by_login(new_login)
      return reply "The login #{new_login} is already taken."
    end

    current_user.login = value.gsub(' ', '')
    current_user.save!

    reply "Your new login is: #{current_user.login}."
  end

  def process_my_name
    reply "Your display name is: #{current_user.display_name}"
  end

  def process_my_name=(value)
    current_user.display_name = value
    current_user.save!

    reply "Your new display name is: #{current_user.display_name}"
  end

  def process_my_password
    reply "Forgot your password? Set it via: .my password newpassword"
  end

  def process_my_password=(value)
    current_user.password = value
    current_user.save!

    reply "Your new password is: #{value}"
  end

  def process_my_number
    sms_channel = current_user.sms_channel
    if sms_channel
      reply "Your phone number is: #{sms_channel.address}"
    else
      reply "You don't have a phone number configured to work with GeoChat."
    end
  end

  def process_my_number=(value)
    reply "You can't change your phone number."
  end

  def process_my_email
    email_channel = current_user.email_channel
    if email_channel
      reply "Your email is: #{email_channel.address}"
    else
      reply "You don't have an email configured to work with GeoChat."
    end
  end

  def process_my_email=(value)
    reply "You can't change your email."
  end

  def process_my_groups
    groups = current_user.groups.map(&:alias).sort
    case groups.count
    when 0
      return reply_dont_belong_to_any_group
    when 1
      reply "Your only group is: #{groups.first}"
    else
      reply "Your groups are: #{groups.join ', '}"
    end
  end

  def process_my_group
    group = current_user.default_group || default_group({
      :no_default_group_message => "Your don't have a default group. To choose one send: .my group groupalias"
    })
    return unless group

    reply "Your default group is: #{group.alias}"
  end

  def process_my_group=(value)
    group = ::Group.find_by_alias value
    if !group
      return reply_group_does_not_exist value
    end

    if !current_user.belongs_to(group)
      return reply "You can't set #{group.alias} as your default group because you don't belong to it."
    end

    current_user.default_group_id = group.id
    current_user.save!

    return reply "Your new default group is: #{group.alias}"
  end

  def process_my_location
    if !current_user.location_known?
      return reply "You never reported your location."
    end

    return reply "You said you was in #{current_user.location} (#{current_user_location_info}) #{time_ago_in_words current_user.location_reported_at} ago."
  end

  def process_my_location=(value)
    update_current_user_location_to value
  end
end
