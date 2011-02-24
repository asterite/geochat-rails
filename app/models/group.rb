class Group < ActiveRecord::Base
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  has_many :messages, :dependent => :destroy

  validates :alias, :presence => true
  validates :alias_downcase, :presence => true, :uniqueness => true

  before_validation :update_alias_downcase

  serialize :data

  def self.find_by_alias(talias)
    self.find_by_alias_downcase talias.downcase
  end

  def owners
    User.joins(:memberships).where('memberships.group_id = ? AND (role = ? OR role = ?)', self.id, :admin, :owner)
  end

  def block(user)
    self.data ||= {}
    blocked_users = self.data[:blocked_users]
    self.data[:blocked_users] = blocked_users = [] unless blocked_users

    was_blocked = if blocked_users.include?(user.id)
      false
    else
      blocked_users << user.id
      membership = user.membership_in(self)
      membership.destroy if membership
      true
    end
    save!

    was_blocked
  end

  def unblock(user)
    return false unless self.data && self.data[:blocked_users] && self.data[:blocked_users].include?(user.id)
    self.data[:blocked_users].delete user.id
    save!
    true
  end

  def as_json(options = {})
    hash = {:alias => self.alias}
    hash[:name] = self.name if self.name.present?
    hash[:requireApprovalToJoin] = self.requires_aproval_to_join?
    hash[:isChatRoom] = self.chatroom?
    hash[:created] = self.created_at
    hash[:updated] = self.updated_at
    hash
  end

  def to_s
    self.alias
  end

  private

  def update_alias_downcase
    self.alias_downcase = self.alias.downcase
  end
end
