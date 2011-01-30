class FixMessagesIndex < ActiveRecord::Migration
  def self.up
    remove_index :messages, :group_id
    add_index :messages, [:group_id, :created_at]
  end

  def self.down
    add_index :messages, :group_id
    remove_index :messages, [:group_id, :created_at]
  end
end
