module T
  extend ActionView::Helpers::DateHelper

  class << self
    def group_created(group)
      "Group '#{group}' created. To require users your approval to join, go to geochat.instedd.org. Invite users by sending: #{group} +PHONE_NUMBER"
    end

    def group_already_exists(group)
      "The group #{group} already exists. Please specify another alias."
    end

    def cannot_create_group_name_too_short(group)
      return "You cannot create a group named '#{group}' because it is too short (minimum is 2 characters)."
    end

    def cannot_create_group_name_reserved(group)
      return "You cannot create a group named '#{group}' because it is a reserved name."
    end

    def you_must_specify_a_group_to_invite
      "You must specify a group to invite the users to, or set a default group."
    end

    def you_must_specify_a_group_to_block(user)
      "You must specify a group to block #{user}, or set a default group."
    end

    def user_has_invited_you(inviter, group)
      "#{inviter} has invited you to group #{group}. You can join by sending: join #{group}"
    end

    def welcome_to_group_signup_and_join(group)
      "Welcome to GeoChat's group #{group}. Tell us your name and join the group by sending: YOUR_NAME join #{group}"
    end

    def welcome_to_group(user, group, memberships_count = 1)
      if user.is_a?(User)
        display_name = user.display_name
        memberships_count = user.memberships.count
      else
        display_name = user
      end
      if memberships_count > 1
        "Welcome #{display_name} to #{group}. Send '#{group} Hello group!'"
      else
        "Welcome #{display_name} to group #{group}. Reply with 'at TOWN NAME' or with any message to say hi to your group!"
      end
    end

    def users_are_now_members_of_group(users, group)
      users = *users
      if users.one?
        "#{users.first} is now a member of group #{group}."
      else
        "#{users.join ','} are all now members of group #{group}."
      end
    end

    def could_not_find_users_for_invitation(users)
      users = *users
      if users.one?
        "Could not find a registered user '#{users.first}' for your invitation."
      else
        "Could not find registered users #{users.join ', '} for your invitation."
      end
    end

    def you_cant_invite_yourself
      "You can't invite yourself."
    end

    def invitations_sent_to_users(users)
      users = *users
      if users.one?
        "Invitation sent to #{users.first}"
      else
        "Invitations sent to #{users.join(', ')}"
      end
    end

    def you_already_belong_to_group(group)
      "You already belong to group #{group}."
    end

    def user_has_accepted_your_invitation(user, group)
      "#{user} has just accepted your invitation to join #{group}."
    end

    def you_cant_leave_group_because_you_dont_belong_to_it(group)
      "You can't leave group #{group} because you don't belong to it."
    end

    def you_cant_leave_group_because_you_are_its_only_owner(group)
      "You can't leave group #{group} because you are its only owner."
    end

    def good_bye_from_group(user, group)
      groups = user.groups
      case groups.count
      when 0
        good_bye_from_only_group user, group
      when 1
        good_bye_from_second_group user, group, groups.first
      else
        good_bye_from_more_than_two_groups user, group
      end
    end

    def good_bye_from_only_group(user, group)
      "Good bye #{user} from your only group #{group}. To join another group send: join groupalias"
    end

    def good_bye_from_second_group(user, group, rest)
      "Good bye #{user} from group #{group}. Now your default group is #{rest}."
    end

    def good_bye_from_more_than_two_groups(user, group)
      "Good bye #{user} from group #{group}."
    end

    def you_dont_belong_to_any_group_yet
      "You don't belong to any group yet. To join a group send: join groupalias"
    end

    def you_are_not_signed_in
      'You are not signed in GeoChat. Send "login USERNAME PASSWORD" to login, or "name YOUR_NAME" or "YOUR_NAME join GROUP_NAME" to register.'
    end

    def user_does_not_exist(user)
      "The user #{user} does not exist."
    end

    def group_does_not_exist(group)
      "The group #{group} does not exist."
    end

    def invitation_pending_for_approval(user, group)
      "An invitation is pending for approval. To approve it send: invite #{group} #{user}"
    end

    def group_requires_approval(group)
      "Group #{group} requires approval to join by an Administrator. We will let you know when you can start sending messages."
    end

    def we_have_turned_on_updates_on_this_channel(channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      "We have turned on updates on this #{name}. Reply with STOP to turn off. Questions email support@instedd.org."
    end

    def you_sent_on_and_we_have_turned_on_udpated_on_this_channel(message, channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      "You sent '#{message}' and we have turned on updates on this #{name}. Reply with STOP to turn off. Questions email support@instedd.org."
    end

    def location_not_found(location)
      "The location '#{location}' could not be found on the map."
    end

    def location_successfuly_updated(place, location_info)
      "Your location was successfully updated to #{place} (#{location_info})"
    end

    def invalid_login
      "Invalid login"
    end

    def hello(user)
      user = user.display_name if user.is_a?(User)
      "Hello #{user}. When you want to remove this device send: bye"
    end

    def device_removed_from_your_account(user)
      user = user.display_name if user.is_a?(User)
      "#{user}, this device has been removed from your account."
    end

    def cant_send_messages_to_disabled_group(group)
      "You can't send messages to #{group} because it is disabled."
    end

    def you_dont_have_a_default_group_prefix_messages
      "You don't have a default group so prefix messages with a group (for example: groupalias Hello!) or set your default group with: .my group groupalias"
    end

    def cant_send_message_to_user_via_group_does_not_belong(user, group)
      "You can't send a message to user #{user} via group #{group} because he/she does not belong to it"
    end

    def cant_send_message_to_user_no_common_group(user)
      "You can't send a message to user #{user} because you don't share a common group"
    end

    def cant_send_message_to_group_invitation_not_approved(group)
      "You can not send messages to the group #{group} as your invitation has not yet been approved by an admin."
    end

    def cant_send_message_to_group_not_a_member(group)
      "You can not send messages to the group #{group} because you are not a member and the group requires approval to join. To request an invitation send: join #{group}"
    end

    def your_login_is(login)
      "Your login is: #{login}"
    end

    def login_taken(login)
      "The login #{login} is already taken."
    end

    def your_new_login_is(login)
      "Your new login is: #{login}."
    end

    def your_display_name_is(display_name)
      "Your display name is: #{display_name}"
    end

    def your_new_display_name_is(display_name)
      "Your new display name is: #{display_name}"
    end

    def forgot_your_password?
      "Forgot your password? Set it via: .my password newpassword"
    end

    def your_new_password_is(password)
      "Your new password is: #{password}"
    end

    def your_phone_number_is(num)
      "Your phone number is: #{num}"
    end

    def you_dont_have_a_phone_number_configured
      "You don't have a phone number configured to work with GeoChat."
    end

    def you_cant_change_your_phone_number
      "You can't change your phone number."
    end

    def your_email_is(email)
      "Your email is: #{email}"
    end

    def you_dont_have_an_email
      "You don't have an email configured to work with GeoChat."
    end

    def you_cant_change_your_email
      "You can't change your email."
    end

    def your_only_group_is(group)
      "Your only group is: #{group}"
    end

    def your_groups_are(groups)
      "Your groups are: #{groups.join ', '}"
    end

    def you_dont_have_a_default_group_choose_one
      "You don't have a default group. To choose one send: .my group groupalias"
    end

    def your_default_group_is(group)
      "Your default group is: #{group}"
    end

    def you_cant_set_group_as_default_group_dont_belong(group)
      "You can't set #{group} as your default group because you don't belong to it."
    end

    def your_new_default_group_is(group)
      "Your new default group is: #{group}"
    end

    def you_never_reported_your_location
      "You never reported your location."
    end

    def you_said_you_was_in(place, location_info, time)
      "You said you was in #{place} (#{location_info}) #{time_ago_in_words time} ago."
    end

    def you_sent_off_and_we_have_turned_off_channel(message, channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      "GeoChat Alerts. You sent '#{message}' and we have turned off updates on this #{name}. Reply with START to turn back on. Questions email support@instedd.org."
    end

    def you_must_specify_a_group_to_set_owner(user)
      "You must specify a group to set #{user} as an owner, or set a default group."
    end

    def user_does_not_belong_to_group(user, group)
      "The user #{user} does not belong to group #{group}."
    end

    def you_are_already_an_owner_of_group(group)
      "You are already an owner of group #{group}."
    end

    def nice_try
      "Nice try :-P"
    end

    def you_cant_block_yourself
      "You can't block yourself"
    end

    def you_cant_set_owner_you_dont_belong_to_group(user, group)
      "You can't set #{user} as an owner of #{group} because you don't belnog to that group."
    end

    def you_cant_block_you_dont_belong_to_group(user, group)
      "You can't block #{user} in #{group} because you don't belnog to that group."
    end

    def you_cant_set_owner_you_are_not_owner(user, group)
      "You can't set #{user} as an owner of #{group} because you are not an owner."
    end

    def user_already_an_owner(user, group)
      "User #{user} is already an owner in group #{group}."
    end

    def user_already_blocked(user, group)
      "#{user} is already blocked in group #{group}."
    end

    def user_set_as_owner(user, group)
      "The user #{user} was successfully set as owner of group #{group}."
    end

    def user_has_made_you_owner(user, group)
      "#{user} has made you owner of group #{group}."
    end

    def a_or_b(a, b)
      "#{a} or #{b}"
    end

    def received_at(time)
      "received at #{Time.now.utc}"
    end

    def at_place(place, location_info = nil)
      if location_info
        "at #{place} (#{location_info})"
      else
        "at #{place}"
      end
    end

    def message_only_to_you(from, others, text)
      if others.empty?
        "#{from} only to you: #{text}"
      else
        "#{from} only to #{others.join ', '} and you: #{text}"
      end
    end

    def message_only_to_user(from, to, text)
      to = *to
      "#{from} only to #{to.join ', '}: #{text}"
    end

    def message_only_to_others_and_you(from, others, text)
      "#{from} only to #{others.join ', '} and you: #{text}"
    end

    def device_belongs_to_another_user
      "This device already belongs to another user. To dettach it send: bye"
    end

    def cannot_signup_name_too_short(name)
      "You cannot signup as '#{name}' because it is too short (minimum is 2 characters)."
    end

    def cannot_signup_name_reserved(name)
      "You cannot signup as '#{name}' because it is a reserved name."
    end

    def welcome_to_geochat(user)
      user = user.display_name if user.is_a?(User)
      "Welcome #{user} to GeoChat! Send HELP for instructions. http://geochat.instedd.org"
    end

    def remember_you_can_log_in(login, password)
      "Remember you can log in to http://geochat.instedd.org by entering your login (#{login}) and the following password: #{password}"
    end

    def to_send_message_to_a_group_you_must_first_join_one
      "To send messages to a group, you must first join one. Send: join GROUP"
    end

    def unknown_command(command, suggestion)
      "Unknown command .#{command}. Maybe you meant to send: .#{suggestion}"
    end

    def you_cant_see_location_no_common_group(user)
      "You can't see the location of #{user} because you don't share a common group."
    end

    def user_never_reported_location(user)
      "#{user} never reported his/her location."
    end

    def user_said_she_was_in(user, place, location_info, time)
      "#{user} said he/she was in #{place} (#{location_info}) #{time_ago_in_words time} ago."
    end

    def user_display_name_is(user)
      "#{user}'s display name is: #{user.display_name}."
    end

    def you_already_invited_user(user, group)
      user = *user
      "You already invited #{user.join ', '} to group #{group}"
    end

    def user_already_belongs_to_group(user, group)
      user = *user
      if user.length == 1
        "The user #{user.first} already belongs to group #{group}"
      else
        "The users #{user.join ', '} already belong to group #{group}"
      end
    end

    def user_blocked(user, group)
      "User #{user} is now blocked in group #{group}"
    end

    def you_cant_block_you_are_not_owner(user, group)
      "You can't block #{user} in group #{group} because you are not an owner."
    end

    def help_help
      "GeoChat help center. Send help followed by a topic. Topics: signup, login, logout, create, join, leave, invite, on, off, my, whereis, whois, owner."
    end

    def help_block
      "To prevent a user from sending and receiving messages in a group send: block GROUP_ALIAS USER_LOGIN"
    end

    def help_create
      "To create a group send: create GROUP_ALIAS"
    end

    def help_invite
      "To invite someone to a group send: GROUP_ALIAS +PHONE_NUMBER_OR_LOGIN"
    end

    def help_join
      "To join a group send: join GROUP_ALIAS"
    end

    def help_language
      "TODO"
    end

    def help_leave
      "To leave a group send: leave GROUP_ALIAS"
    end

    def help_login
      "To login to GeoChat from this channel send: login YOUR_LOGIN YOUR_PASSWORD"
    end

    def help_logout
      "To logout from GeoChat send: logout"
    end

    def help_my
      "To change your settings send: .my OPTION or .my OPTION VALUE. Options: login, password, name, email, phone, location, group, groups"
    end

    def help_off
      "To stop receiving messages from this channel send: off"
    end

    def help_on
      "To start receiving messages from this channel send: on"
    end

    def help_owner
      "To make a user owner of a group send: owner GROUP_ALIAS USER_LOGIN"
    end

    def help_ping
      "To ping GeoChat send: ping, followed by any message"
    end

    def help_signup
      "To signup in GeoChat send: name YOUR_NAME"
    end

    def help_where_is
      "To find out the location of a user send: .whereis USER_LOGIN"
    end

    def help_who_is
      "To find out the display name of a user send: .whois USER_LOGIN"
    end
  end
end
