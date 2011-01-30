class AddAliasDowncaseToGroup < ActiveRecord::Migration
  def self.up
    add_column :groups, :alias_downcase, :string
  end

  def self.down
    remove_column :groups, :alias_downcase
  end
end
