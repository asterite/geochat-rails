class AddDataToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :data, :text
  end

  def self.down
    remove_column :users, :data
  end
end
