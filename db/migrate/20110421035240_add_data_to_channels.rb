class AddDataToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :data, :text
  end

  def self.down
    remove_column :channels, :data
  end
end
