class CreateCustomChannels < ActiveRecord::Migration
  def self.up
    create_table :custom_channels do |t|
      t.integer :group_id
      t.string :name
      t.string :type
      t.string :direction
      t.text :data

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_channels
  end
end
