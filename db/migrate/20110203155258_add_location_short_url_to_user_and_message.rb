class AddLocationShortUrlToUserAndMessage < ActiveRecord::Migration
  def self.up
    add_column :users, :location_short_url, :string
    add_column :messages, :location_short_url, :string
  end

  def self.down
    remove_column :users, :location_short_url
    remove_column :messages, :location_short_url
  end
end
