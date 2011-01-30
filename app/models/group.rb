class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships

  validates :alias, :presence => true
  validates :alias_downcase, :presence => true, :uniqueness => true

  before_validation :update_alias_downcase

  def self.find_by_alias(talias)
    self.find_by_alias_downcase talias.downcase
  end

  def owners
    User.joins(:memberships).where('memberships.group_id = ? AND (role = ? OR role = ?)', self.id, :admin, :owner)
  end

  private

  def update_alias_downcase
    self.alias_downcase = self.alias.downcase
  end
end
