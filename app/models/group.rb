class Group < ActiveRecord::Base
  has_many :memberships
  has_many :users, :through => :memberships

  validates :alias, :presence => true, :uniqueness => true

  def owners
    User.joins(:memberships).where('memberships.group_id = ? AND (role = ? OR role = ?)', self.id, :admin, :owner)
  end
end
