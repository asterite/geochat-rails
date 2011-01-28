class AddLocationToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :lat, :decimal, :precision => 10, :scale => 6
    add_column :users, :lon, :decimal, :precision => 10, :scale => 6
    add_column :users, :location, :string
  end

  def self.down
    remove_column :users, :location
    remove_column :users, :lat
    remove_column :users, :lon
  end
end
