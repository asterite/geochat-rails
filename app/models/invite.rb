class Invite < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :requestor, :class_name => 'User'
  before_save :cache_in_data

  data_accessor :user_login
  data_accessor :requestor_login
  data_accessor :group_alias

  private

  def cache_in_data
    self.user_login = user.login
    self.requestor_login = requestor.login if requestor_id
    self.group_alias = group.alias
  end

end
