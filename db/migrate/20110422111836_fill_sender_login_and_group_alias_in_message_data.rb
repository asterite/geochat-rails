class FillSenderLoginAndGroupAliasInMessageData < ActiveRecord::Migration
  def self.up
    Message.includes([:group, :sender]).find_each do |msg|
      msg.group_alias = msg.group.alias
      msg.sender_login = msg.sender.login
      msg.save!
    end
  end

  def self.down
  end
end
