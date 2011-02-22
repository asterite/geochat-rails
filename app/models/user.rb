require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :channels, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships

  validates :login, :presence => true
  validates :login_downcase, :presence => true, :uniqueness => true
  validates :password, :presence => true, :if => proc {|u| !u.created_from_invite?}

  belongs_to :default_group, :class_name => 'Group'
  before_validation :update_login_downcase
  before_save :update_location_reported_at
  before_save :encode_password, :if => proc{|u| u.password_changed?}

  def self.find_by_login(login)
    self.find_by_login_downcase login.downcase
  end

  def self.find_by_mobile_number(number)
    User.joins(:channels).where('channels.protocol = ? and channels.address = ?', 'sms', number).first
  end

  def self.find_suitable_login(suggested_login)
    login = suggested_login
    index = 2
    while self.find_by_login(login)
      login = "#{suggested_login}#{index}"
      index += 1
    end
    login
  end

  def self.find_by_login_or_mobile_number(search)
    user = self.find_by_login search
    user = self.find_by_mobile_number search unless user
    user
  end

  def self.find_by_login_and_created_from_invite(login, created_from_invite)
    self.find_by_login_downcase_and_created_from_invite login, created_from_invite
  end

  def self.authenticate(login, password)
    user = User.find_by_login login
    return nil unless user

    salt = user.password[0 .. 24]
    encoded_password = self.hash_password salt, password
    encoded_password == user.password[24 .. -1] ? user : nil
  end

  def create_group(options = {})
    group = Group.create! options
    join group, :as => :owner
    group
  end

  # options:
  # :as => the role to join (:member by default)
  def join(group, options = {})
    Membership.create! :user => self, :group => group, :role => (options[:as] || :member)
  end

  # user can be a User or a string, in which case a new User will be created with that login
  # options = :to => group
  def invite(user, options = {})
    group = options[:to]
    if user.kind_of?(String)
      user = User.create! :login => user, :created_from_invite => true
    end
    Invite.create! :group => group, :user => user, :admin_accepted => self.is_owner_of(group), :requestor => self
  end

  def request_join(group)
    Invite.create! :user => self, :group => group, :user_accepted => true
  end

  def role_in(group)
    Membership.find_by_group_id_and_user_id(group.id, self.id).try(:role).try(:to_sym)
  end

  def is_owner_of(group)
    role_in(group) == :owner
  end

  def shares_a_common_group_with(user)
    result = self.class.connection.execute "select 1 from memberships m1, memberships m2 where m1.group_id = m2.group_id and m1.user_id = #{self.id} and m2.user_id = #{user.id}"
    result.count > 0
  end

  def membership_in(group)
    Membership.where('user_id = ? and group_id = ?', self.id, group.id).first
  end

  def belongs_to(group)
    Membership.where('user_id = ? and group_id = ?', self.id, group.id).exists?
  end

  def coords=(array)
    self.lat = array.first
    self.lon = array.second
  end

  def location_known?
    self.lat && self.lon
  end

  def sms_channel
    self.channels.where(:protocol => 'sms').first
  end

  def email_channel
    self.channels.where(:protocol => 'mailto').first
  end

  def active_channels
    if self.channels.loaded?
      self.channels.select &:active?
    else
      self.channels.where('status = ?', :on)
    end
  end

  def as_json(options = {})
    hash = {:login => self.login}
    hash[:displayName] = self.display_name if self.display_name.present?
    hash[:lat] = self.lat.to_f if self.lat.present?
    hash[:long] = self.lon.to_f if self.lon.present?
    hash[:location] = self.location if self.location.present?
    hash[:created] = self.created_at
    hash[:updated] = self.updated_at
    hash
  end

  def to_s
    self.login
  end

  private

  def update_location_reported_at
    if self.lat_changed? || self.lon_changed? || self.location_changed?
      self.location_reported_at = Time.now.utc
    end
  end

  def update_login_downcase
    self.login_downcase = self.login.downcase
  end

  def encode_password
    salt = ActiveSupport::SecureRandom.base64(16)
    encoded_password = self.class.hash_password salt, self.password
    self.password = "#{salt}#{encoded_password}"
  end

  def self.hash_password(salt, password)
    decoded_salt = ActiveSupport::Base64.decode64 salt
    ActiveSupport::Base64.encode64(Digest::SHA1.digest(decoded_salt + Iconv.conv('ucs-2le', 'utf-8', password))).strip
  end
end
