class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  validates_uniqueness_of :user_id, :scope => :group_id

  after_create :increment_user_groups_count_and_clear_interesting_requests_count_cache
  after_update :clear_user_interesting_requests_count_cache
  after_destroy :decrement_user_groups_count_and_clear_interesting_requests_count_cache

  after_create :increment_group_users_count
  after_destroy :decrement_group_users_count

  after_destroy :unset_user_default_group

  def member?
    !admin?
  end

  def make_admin
    return false if self.admin?

    self.admin = true
    self.save!
    true
  end

  private

  def increment_user_groups_count_and_clear_interesting_requests_count_cache
    user.groups_count += 1
    user.interesting_requests_count_cache = nil
    user.save!
  end

  def decrement_user_groups_count_and_clear_interesting_requests_count_cache
    user.groups_count -= 1
    user.interesting_requests_count_cache = nil
    user.save!
  end

  def clear_user_interesting_requests_count_cache
    user.interesting_requests_count_cache = nil
    user.save!
  end

  def increment_group_users_count
    group.users_count += 1
    group.save!
  end

  def decrement_group_users_count
    group.users_count -= 1
    group.save!
  end

  def unset_user_default_group
    if user.default_group_id == self.group.id
      user.default_group_id = nil
      user.save!
    end
  end
end
