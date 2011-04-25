class Membership < ActiveRecord::Base
  Roles = %w(member admin owner).map(&:to_sym)

  include Comparable

  belongs_to :user
  belongs_to :group

  validates_uniqueness_of :user_id, :scope => :group_id
  validates_inclusion_of :role, :in => Roles

  after_create :increment_user_groups_count
  after_destroy :decrement_user_groups_count

  after_create :increment_group_users_count
  after_destroy :decrement_group_users_count

  after_destroy :unset_user_default_group

  attr_reader_as_symbol :role

  [:owner, :admin, :member].each do |role|
    class_eval %Q(
      def #{role}?
        role == :#{role}
      end
    )
  end

  def change_role_to(role)
    return false if self.role == role

    self.role = role
    self.save!
    true
  end

  def <=>(other)
    case role
    when :member
      other.member? ? 0 : -1
    when :admin
      other.member? ? 1 : (other.admin? ? 0 : -1)
    when :owner
      other.owner? ? 0 : 1
    end
  end

  private

  def increment_user_groups_count
    user.groups_count += 1
    user.save!
  end

  def decrement_user_groups_count
    user.groups_count -= 1
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
