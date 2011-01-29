class AddMessageIndices < ActiveRecord::Migration
  def self.up
    add_index :messages, :group_id
    add_index :messages, :sender_id
    add_index :messages, :receiver_id
  end

  def self.down
    remove_index :messages, :group_id
    remove_index :messages, :sender_id
    remove_index :messages, :receiver_id
  end
end
