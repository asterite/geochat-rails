class AddConfirmationCodeToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :confirmation_code, :string
  end

  def self.down
    remove_column :channels, :confirmation_code
  end
end
