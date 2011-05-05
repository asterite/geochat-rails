class Invite < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :requestor, :class_name => 'User'
  before_save :cache_in_data

  validates_presence_of :user_id
  validates_presence_of :group_id

  after_create :clear_user_interesting_requests_count_cache
  after_update :clear_user_interesting_requests_count_cache
  after_destroy :clear_user_interesting_requests_count_cache

  data_accessor :user_login
  data_accessor :requestor_login
  data_accessor :group_alias

  private

  def cache_in_data
    self.user_login = user.login
    self.requestor_login = requestor.login if requestor_id
    self.group_alias = group.alias
  end

  def clear_user_interesting_requests_count_cache
    self.user.interesting_requests_count_cache = nil
    self.user.save!
  end

end
