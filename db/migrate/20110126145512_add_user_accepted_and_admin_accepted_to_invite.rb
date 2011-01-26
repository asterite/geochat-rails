class AddUserAcceptedAndAdminAcceptedToInvite < ActiveRecord::Migration
  def self.up
    add_column :invites, :user_accepted, :boolean, :default => false
    add_column :invites, :admin_accepted, :boolean, :default => false
  end

  def self.down
    remove_column :invites, :admin_accepted
    remove_column :invites, :user_accepted
  end
end
