class User < ActiveRecord::Base
  has_many :channels
  has_many :memberships
  has_many :groups, :through => :memberships

  validates :login, :presence => true, :uniqueness => true

  belongs_to :default_group, :class_name => 'Group'

  def self.find_by_mobile_number(number)
    User.joins(:channels).where('channels.protocol = ? and channels.address = ?', 'sms', number).first
  end

  def join(group)
    Membership.create! :user => self, :group => group, :role => :member
  end

  def make_owner_of(group)
    membership = Membership.find_by_group_id_and_user_id(group.id, self.id)
    membership.role = :owner
    membership.save!
  end

  def role_in(group)
    Membership.find_by_group_id_and_user_id(group.id, self.id).try(:role).try(:to_sym)
  end

  def is_owner_of(group)
    role_in(group) == :owner
  end
end
