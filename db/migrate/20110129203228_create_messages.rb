class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :sender_id
      t.integer :group_id
      t.integer :receiver_id
      t.string :text
      t.decimal :lat, :precision => 10, :scale => 6
      t.decimal :lon, :precision => 10, :scale => 6
      t.string :location

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
