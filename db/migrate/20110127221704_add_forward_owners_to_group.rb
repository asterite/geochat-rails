class AddForwardOwnersToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :forward_owners, :boolean, :default => false
  end

  def self.down
    remove_column :groups, :forward_owners
  end
end
