class AddCreatedFromInviteToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :created_from_invite, :boolean, :default => false
  end

  def self.down
    remove_column :users, :created_from_invite
  end
end
