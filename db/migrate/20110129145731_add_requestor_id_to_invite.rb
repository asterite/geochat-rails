class AddRequestorIdToInvite < ActiveRecord::Migration
  def self.up
    add_column :invites, :requestor_id, :integer
  end

  def self.down
    remove_column :invites, :requestor_id
  end
end
