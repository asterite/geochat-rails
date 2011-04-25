class CreateCustomLocations < ActiveRecord::Migration
  def self.up
    create_table :custom_locations do |t|
      t.string :name
      t.string :name_downcase
      t.decimal :lat, :precision => 10, :scale => 6
      t.decimal :lon, :precision => 10, :scale => 6
      t.string :location
      t.string :location_short_url
      t.references :locatable, :polymorphic => true

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_locations
  end
end
