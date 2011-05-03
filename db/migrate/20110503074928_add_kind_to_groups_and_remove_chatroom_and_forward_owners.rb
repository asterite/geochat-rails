class AddKindToGroupsAndRemoveChatroomAndForwardOwners < ActiveRecord::Migration
  def self.up
    add_column :groups, :kind, :string, :default => 'chatroom'

    remove_column :groups, :chatroom
    remove_column :groups, :forward_owners
  end

  def self.down
    add_column :groups, :forward_owners, :boolean, :default => false
    add_column :groups, :chatroom, :boolean, :default => true

    remove_column :groups, :kind
  end
end
