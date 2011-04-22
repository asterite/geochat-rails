class FixRequiredApprovalToJoin < ActiveRecord::Migration
  def self.up
    rename_column :groups, :requires_aproval_to_join, :requires_approval_to_join
  end

  def self.down
    rename_column :groups, :requires_approval_to_join, :requires_aproval_to_join
  end
end
