class AddDataToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :data, :text
  end

  def self.down
    remove_column :messages, :data
  end
end
