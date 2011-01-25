class User < ActiveRecord::Base
  has_many :channels
  has_many :group_users
  has_many :groups, :through => :group_users
end
