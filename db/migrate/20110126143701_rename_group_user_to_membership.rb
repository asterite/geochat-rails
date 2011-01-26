class RenameGroupUserToMembership < ActiveRecord::Migration
  def self.up
    rename_table :group_users, :memberships
  end

  def self.down
    rename_table :memberships, :group_users
  end
end
