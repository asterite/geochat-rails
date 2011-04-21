class ChangeConfirmationCodeToActivationCode < ActiveRecord::Migration
  def self.up
    rename_column :channels, :confirmation_code, :activation_code
  end

  def self.down
    rename_column :channels, :activation_code, :confirmation_code
  end
end
