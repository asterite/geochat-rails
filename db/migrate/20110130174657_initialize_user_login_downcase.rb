class InitializeUserLoginDowncase < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      user.login_downcase = user.login
      user.save!
    end
  end

  def self.down
  end
end
