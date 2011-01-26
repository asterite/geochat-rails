class AddDefaultGroupToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :default_group_id, :integer
  end

  def self.down
    remove_column :users, :default_group_id
  end
end
