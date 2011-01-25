class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.string :protocol
      t.string :address
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :channels
  end
end
