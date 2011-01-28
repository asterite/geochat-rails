class AddLocationReportedAtToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :location_reported_at, :datetime
  end

  def self.down
    remove_column :users, :location_reported_at
  end
end
