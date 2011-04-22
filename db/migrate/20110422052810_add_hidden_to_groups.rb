class AddHiddenToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :hidden, :boolean, :default => true
  end

  def self.down
    remove_column :groups, :hidden
  end
end
