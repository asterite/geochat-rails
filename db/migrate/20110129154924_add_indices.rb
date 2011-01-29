class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :channels, [:protocol, :address]
    add_index :channels, [:user_id, :status]
    add_index :users, [:login, :created_from_invite]
    add_index :groups, :alias
    add_index :memberships, :group_id
    add_index :memberships, [:group_id, :user_id]
    add_index :invites, [:group_id, :user_id]
  end

  def self.down
    remove_index :channels, [:protocol, :address]
    remove_index :channels, [:user_id, :status]
    remove_index :users, [:login, :created_from_invite]
    remove_index :groups, :alias
    remove_index :memberships, :group_id
    remove_index :memberships, [:group_id, :user_id]
    remove_index :invites, [:group_id, :user_id]
  end
end
