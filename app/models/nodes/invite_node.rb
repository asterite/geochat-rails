class InviteNode < Node
  command_after_group do
    name 'invite'
    name 'i', :prefix => :required
    name '\+', :prefix => :none, :space_after_command => false
    args :users
  end

  requires_user_to_be_logged_in

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
    group = fix_group || default_group({:no_default_group_message => T.you_must_specify_a_group_to_invite }) or return
    membership = current_user.membership_in(group) or return reply T.you_cant_invite_you_dont_belong(group)

    setup_reply_vars

    self.users.each do |name|
      user = User.find_by_login_or_mobile_number name

      check_user_not_found name, user, group and next
      check_invited_self user and next
      check_already_belongs user, group and next

      invites = Invite.find_all_by_group_id_and_user_id group.id, user.id

      check_already_invited user, invites and next
      check_no_invites_or_user_cannot_invite name, user, group, invites, membership and next
      check_joined user, group, invites
      mark_invites_as_accepted_by_admin_and_sent invites
    end

    send_replies group
  end

  private

  def setup_reply_vars
    @sent = []
    @joined = []
    @not_found = []
    @already_invited = []
    @already_belongs = []
    @invited_self = false
  end

  def check_user_not_found(name, user, group)
    if !user
      # It might be a mobile number => invite that number
      if name.integer?
        current_user.invite name, :to => group
        send_message :to => "sms://#{name}", :body => T.welcome_to_group_signup_and_join(group)
        @sent << name
      else
        @not_found << name unless @not_found.include? name
      end
      true
    else
      false
    end
  end

  def check_invited_self(user)
    if user == current_user
      @invited_self = true
      true
    else
      false
    end
  end

  def check_already_belongs(user, group)
    if user.belongs_to? group
      @already_belongs << user.login
      true
    else
      false
    end
  end

  def check_already_invited(user, invites)
    if invites.any?{|x| x.requestor_id == current_user.id}
      @already_invited << user.login
      true
    else
      false
    end
  end

  def check_no_invites_or_user_cannot_invite(name, user, group, invites, membership)
    if invites.empty? || membership.member?
      current_user.invite user, :to => group
      send_message_to_user user, :user_has_invited_you, :args => [current_user, group]
      @sent << name
      true
    else
      false
    end
  end

  def check_joined(user, group, invites)
    if invites.any?{|x| x.user_accepted}
      join_and_welcome user, group
      invites.each &:destroy
      @joined << user.login
      true
    else
      false
    end
  end

  def mark_invites_as_accepted_by_admin_and_sent(invites)
    invites.each { |i| i.admin_accepted = true; i.save! }
    @sent << name
  end

  def send_replies(group)
    reply T.users_are_now_members_of_group(@joined, group), :group => group if @joined.present?
    reply T.could_not_find_users_for_invitation(@not_found), :group => group if @not_found.present?
    reply T.you_cant_invite_yourself, :group => group if @invited_self
    reply T.you_already_invited_user(@already_invited, group), :group => group if @already_invited.present?
    reply T.user_already_belongs_to_group(@already_belongs, group), :group => group if @already_belongs.present?
    reply T.invitations_sent_to_users(@sent), :group => group if @sent.present?
  end
end
