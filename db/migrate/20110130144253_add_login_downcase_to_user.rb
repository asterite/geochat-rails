class AddLoginDowncaseToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :login_downcase, :string
  end

  def self.down
    remove_column :users, :login_downcase
  end
end
