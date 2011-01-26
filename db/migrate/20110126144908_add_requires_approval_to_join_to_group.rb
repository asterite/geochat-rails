class AddRequiresApprovalToJoinToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :requires_aproval_to_join, :boolean, :default => false
  end

  def self.down
    remove_column :groups, :requires_aproval_to_join
  end
end
