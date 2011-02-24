class AddDataToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :data, :text
  end

  def self.down
    remove_column :groups, :data
  end
end
