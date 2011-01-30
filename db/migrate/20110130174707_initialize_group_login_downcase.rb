class InitializeGroupLoginDowncase < ActiveRecord::Migration
  def self.up
    Group.all.each do |group|
      group.alias_downcase = group.alias
      group.save!
    end
  end

  def self.down
  end
end
