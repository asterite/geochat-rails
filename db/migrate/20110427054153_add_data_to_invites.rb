class AddDataToInvites < ActiveRecord::Migration
  def self.up
    add_column :invites, :data, :text
  end

  def self.down
    remove_column :invites, :data
  end
end
