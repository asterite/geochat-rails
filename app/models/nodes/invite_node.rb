class InviteNode < Node
  command_after_group do
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
      :no_default_group_message => T.you_must_specify_a_group_to_invite
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

        invites = Invite.find_all_by_group_id_and_user_id group.id, user.id
        if invites.present?
          if current_user.is_owner_of(group)
            if invites.any?{|x| x.user_accepted}
              join user, group
              invites.each &:destroy
              joined << user.login
            else
              invites.each do |invite|
                invite.admin_accepted = true
                invite.save!
              end
              sent << name
            end
          else
            if invites.all?{|x| x.requestor_id != current_user.id}
              current_user.invite user, :to => group
              send_message_to_user user, T.user_has_invited_you(current_user, group)
              sent << user.login
            else
              # User is already invited... should we resend the invitation?
              # TOOD: at least tell the user that he was invited?
            end
          end
        else
          current_user.invite user, :to => group
          send_message_to_user user, T.user_has_invited_you(current_user, group)
          sent << name
        end
      else
        if name.integer?
          current_user.invite name, :to => group
          send_message :to => "sms://#{name}", :body => T.welcome_to_group_signup_and_join(group)
          sent << name
        else
          not_found << name unless not_found.include? name
        end
      end
    end

    reply T.users_are_now_members_of_group(joined, group) if joined.present?
    reply T.could_not_find_users_for_invitation(not_found) if not_found.present?
    reply T.you_cant_invite_yourself if invited_self
    reply T.invitations_sent_to_users(sent) if sent.present?
  end
end
