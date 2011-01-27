class AddChatroomToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :chatroom, :boolean, :default => true
  end

  def self.down
    remove_column :groups, :chatroom
  end
end
