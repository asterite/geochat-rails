class MoveIndicesToDowncaseVersion < ActiveRecord::Migration
  def self.up
    remove_index :users, [:login, :created_from_invite]
    add_index :users, [:login_downcase, :created_from_invite]

    remove_index :groups, :alias
    add_index :groups, :alias_downcase
  end

  def self.down
    add_index :users, [:login, :created_from_invite]
    remove_index :users, [:login_downcase, :created_from_invite]

    add_index :groups, :alias
    remove_index :groups, :alias_downcase
  end
end
