class Invite < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :requestor, :class_name => 'User'
end
