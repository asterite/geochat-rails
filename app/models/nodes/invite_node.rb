class InviteNode < Node
  command
  command_without_group

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
end
