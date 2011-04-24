class AddLatLonAndLocationToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :lat, :decimal, :precision => 10, :scale => 6
    add_column :groups, :lon, :decimal, :precision => 10, :scale => 6
    add_column :groups, :location, :string
  end

  def self.down
    remove_column :groups, :location
    remove_column :groups, :lon
    remove_column :groups, :lat
  end
end
