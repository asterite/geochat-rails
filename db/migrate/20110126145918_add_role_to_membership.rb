class AddRoleToMembership < ActiveRecord::Migration
  def self.up
    add_column :memberships, :role, :string
  end

  def self.down
    remove_column :memberships, :role
  end
end
