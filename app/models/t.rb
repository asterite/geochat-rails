module T
  extend ActionView::Helpers::DateHelper

  class << self
    include I18n

    def method_missing(name, *args)
      if args.length == 1 && args.first.is_a?(Hash)
        I18n.t! name, *args
      else
        I18n.t! name, :name => args[0]
      end
    end

    def user_has_invited_you(inviter, group)
      I18n.t! :user_has_invited_you, :inviter => inviter, :group => group
    end

    def welcome_to_group(user, group)
      if user.groups_count > 1
        welcome_to_non_first_group user, group
      else
        welcome_to_first_group user, group
      end
    end

    def welcome_to_first_group(user, group)
      user = user.display_name if user.is_a? User
      I18n.t! :welcome_to_first_group, :user => user, :group => group
    end

    def welcome_to_non_first_group(user, group)
      user = user.display_name if user.is_a? User
      I18n.t! :welcome_to_non_first_group, :user => user, :group => group
    end

    def users_are_now_members_of_group(users, group)
      users = *users
      if users.one?
        I18n.t! :user_is_now_a_member_of_group, :user => users.first, :group => group
      else
        I18n.t! :users_are_all_now_members_of_group, :users => users.join(', '), :group => group
      end
    end

    def could_not_find_users_for_invitation(users)
      users = *users
      if users.one?
        I18n.t! :could_not_find_registered_user, :name => users.first
      else
        I18n.t! :could_not_find_registered_users, :name => users.join(', ')
      end
    end

    def invitations_sent_to_users(users)
      users = *users
      if users.one?
        I18n.t! :invitation_sent_to_user, :name => users.first
      else
        I18n.t! :invitations_sent_to_users, :name => users.join(', ')
      end
    end

    def user_has_accepted_your_invitation(user, group)
      I18n.t! :user_has_accepted_your_invitation, :user => user, :group => group
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
      I18n.t! :good_bye_from_only_group, :user => user, :group => group
    end

    def good_bye_from_second_group(user, group, rest)
      I18n.t! :good_bye_from_second_group, :user => user, :group => group, :rest => rest
    end

    def good_bye_from_more_than_two_groups(user, group)
      I18n.t! :good_bye_from_more_than_two_groups, :user => user, :group => group
    end

    def invitation_pending_for_approval(user, group)
      I18n.t! :invitation_pending_for_approval, :user => user, :group => group
    end

    def we_have_turned_on_updates_on_this_channel(channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      I18n.t! :we_have_turned_on_updates_on_this_channel, :name => name
    end

    def you_sent_on_and_we_have_turned_on_udpated_on_this_channel(message, channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      I18n.t! :you_sent_on_and_we_have_turned_on_udpated_on_this_channel, :message => message, :name => name
    end

    def location_successfuly_updated(place, location_info)
      I18n.t! :location_successfuly_updated, :place => place, :location_info => location_info
    end

    def hello(user)
      user = user.display_name if user.is_a?(User)
      I18n.t! :hello, :name => user
    end

    def device_removed_from_your_account(user)
      user = user.display_name if user.is_a?(User)
      I18n.t! :device_removed_from_your_account, :name => user
    end

    def cant_send_message_to_user_via_group_does_not_belong(user, group)
      I18n.t! :cant_send_message_to_user_via_group_does_not_belong, :user => user, :group => group
    end

    def your_groups_are(groups)
      I18n.t! :your_groups_are, :name => groups.join(', ')
    end

    def you_said_you_was_in(place, location_info, time)
      I18n.t! :you_said_you_was_in, :place => place, :location_info => location_info, :time => time_ago_in_words(time)
    end

    def you_sent_off_and_we_have_turned_off_channel(message, channel)
      name = channel.is_a?(Channel) ? channel.protocol_name : channel
      I18n.t! :you_sent_off_and_we_have_turned_off_channel, :message => message, :name => name
    end

    def user_does_not_belong_to_group(user, group)
      I18n.t! :user_does_not_belong_to_group, :user => user, :group => group
    end

    def you_cant_set_owner_you_dont_belong_to_group(user, group)
      I18n.t! :you_cant_set_owner_you_dont_belong_to_group, :user => user, :group => group
    end

    def you_cant_block_you_dont_belong_to_group(user, group)
      I18n.t! :you_cant_block_you_dont_belong_to_group, :user => user, :group => group
    end

    def you_cant_set_owner_you_are_not_owner(user, group)
      I18n.t! :you_cant_set_owner_you_are_not_owner, :user => user, :group => group
    end

    def user_already_an_owner(user, group)
      I18n.t! :user_already_an_owner, :user => user, :group => group
    end

    def user_already_blocked(user, group)
      I18n.t! :user_already_blocked, :user => user, :group => group
    end

    def user_set_as_owner(user, group)
      I18n.t! :user_set_as_owner, :user => user, :group => group
    end

    def user_has_made_you_owner(user, group)
      I18n.t! :user_has_made_you_owner, :user => user, :group => group
    end

    def a_or_b(a, b)
      I18n.t! :a_or_b, :a => a, :b => b
    end

    def received_at(time)
      I18n.t! :received_at, :name => Time.now.utc
    end

    def at_place(place, location_info = nil)
      if location_info
        I18n.t! :at_place_with_location_info, :place => place, :location_info => location_info
      else
        I18n.t! :at_place, :name => place
      end
    end

    def message_only_to_you(from, others)
      if others.empty?
        I18n.t! :message_only_to_you, :name => from
      else
        I18n.t! :message_only_to_others_and_you, :from => from, :others => others.join(', ')
      end
    end

    def message_only_to_users(from, to)
      to = *to
      I18n.t! :message_only_to_users, :from => from, :to => to.join(', ')
    end

    def welcome_to_geochat(user)
      user = user.display_name if user.is_a?(User)
      I18n.t! :welcome_to_geochat, :name => user
    end

    def remember_you_can_log_in(login, password)
      I18n.t! :remember_you_can_log_in, :login => login, :password => password
    end

    def unknown_command(command, suggestion)
      I18n.t! :unknown_command, :command => command, :suggestion => suggestion
    end

    def user_said_she_was_in(user, place, location_info, time)
      I18n.t! :user_said_she_was_in, :user => user, :place => place, :location_info => location_info, :time => time_ago_in_words(time)
    end

    def user_display_name_is(user)
      I18n.t! :user_display_name_is, :user => user, :display_name => user.display_name
    end

    def you_already_invited_user(user, group)
      user = *user
      I18n.t! :you_already_invited_user, :user => user.join(', '), :group => group
    end

    def user_already_belongs_to_group(user, group)
      user = *user
      if user.length == 1
        I18n.t! :user_already_belongs_to_group, :user => user.first, :group => group
      else
        I18n.t! :users_already_belong_to_group, :users => user.join(', '), :group => group
      end
    end

    def user_blocked(user, group)
      I18n.t! :user_blocked, :user => user, :group => group
    end

    def you_cant_block_you_are_not_owner(user, group)
      I18n.t! :you_cant_set_owner_you_are_not_owner, :user => user, :group => group
    end
  end
end
