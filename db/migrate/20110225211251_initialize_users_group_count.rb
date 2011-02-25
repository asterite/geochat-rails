class InitializeUsersGroupCount < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      user.groups_count = user.memberships.count
      user.save! unless user.groups_count.zero?
    end
  end

  def self.down
  end
end
