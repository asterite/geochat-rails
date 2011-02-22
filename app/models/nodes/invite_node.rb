class InviteNode < Node
  command
  command_without_group
  Help = "To invite someone to a group send: GROUP_ALIAS +PHONE_NUMBER_OR_LOGIN"

  attr_accessor :group
  attr_accessor :users

  Command = ::Command.new self do
    name 'invite'
    name 'i', :prefix => :required
    name '\+', :prefix => :none, :space_after_command => false
    args :users
  end

  def after_scan
    users = self.users.split
    if users.length == 1 || self.matched_name == '+'
      self.users = users
    else
      self.users = []
      only_users = false
      users.each_with_index do |user, i|
        user = user[1 .. -1] if user.start_with? '@'
        starts_with_plus = user.start_with? '+'
        digits = user =~ /^\d+$/

        if i == 1 && !starts_with_plus && users.length == 2 && !self.group
          self.group = user
        elsif self.group || only_users || starts_with_plus || digits
          if starts_with_plus
            user = user[1 .. -1]
            only_users = true
          end
          self.users << user
        else
          self.group = user
        end
      end
    end
  end

  def after_scan_with_group
    self.users = self.users.split.without_prefix! '+'
  end

  def fix_group
    if self.group
      group = Group.find_by_alias self.group
      if !group
        group = Group.find_by_alias self.users.first
        if group
          self.users = [self.group]
        else
          self.users.insert 0, self.group
        end
      end
    end
    group
  end

  def process
    return reply_not_logged_in unless current_user

    group = fix_group || default_group({
      :no_default_group_message => "You must specify a group to invite the users to, or set a default group.",
    })
    return unless group

    sent = []
    joined = []
    not_found = []
    invited_self = false

    @users.each do |name|
      user = User.find_by_login_or_mobile_number name

      if user
        if user == current_user
          invited_self = true
          next
        end

        invite = Invite.find_by_group_and_user group, user
        if invite
          if invite.user_accepted
            if current_user.is_owner_of(group)
              join user, group
              invite.destroy

              joined << user.login
            else
              sent << name
            end
          elsif current_user.is_owner_of(group)
            invite.admin_accepted = true
            invite.save!
            sent << name
          else
            # Invite was already sent... should we resend it?
          end
        else
          current_user.invite user, :to => group
          send_message_to_user user, "#{current_user.login} has invited you to group #{group.alias}. You can join by sending: join #{group.alias}"
          sent << name
        end
      else
        if name.integer?
          current_user.invite name, :to => group
          send_message :to => "sms://#{name}", :body => "Welcome to GeoChat's group #{group.alias}. Tell us your name and join the group by sending: YOUR_NAME join #{group.alias}"
          sent << name
        else
          not_found << name unless not_found.include? name
        end
      end
    end

    if joined.present?
      if joined.one?
        reply "#{joined.first} is now a member of group #{group.alias}."
      else
        reply "#{joined.join ','} are all now members of group #{group.alias}."
      end
    end
    if not_found.present?
      if not_found.one?
        reply "Could not find a registered user '#{not_found.first}' for your invitation."
      else
        users = not_found.map{|x| "'#{x}'"}.join ', '
        reply "Could not find registered users #{users} for your invitation."
      end
    end
    if invited_self
      reply "You can't invite yourself."
    end
    if sent.present?
      reply "Invitation/s sent to #{sent.join(', ')}"
    end
  end
end
