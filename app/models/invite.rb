class Invite < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :requestor, :class_name => 'User'

  def self.find_by_group_and_user(group, user)
    self.find_by_group_id_and_user_id group.id, user.id
  end
end
