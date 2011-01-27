class AddEnabledToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :enabled, :boolean, :default => true
  end

  def self.down
    remove_column :groups, :enabled
  end
end
