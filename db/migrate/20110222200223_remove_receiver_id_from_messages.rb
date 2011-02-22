class RemoveReceiverIdFromMessages < ActiveRecord::Migration
  def self.up
    remove_column :messages, :receiver_id
  end

  def self.down
    add_column :messages, :receiver_id, :integer
  end
end
