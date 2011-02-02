class EncodePasswords < ActiveRecord::Migration
  def self.up
    User.all.each do |user|
      encoded_password = user.send :encode_password
      User.connection.execute "UPDATE users SET password = '#{encoded_password}'"
    end
  end

  def self.down
  end
end
