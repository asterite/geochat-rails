class User < ActiveRecord::Base
  has_many :channels
end
