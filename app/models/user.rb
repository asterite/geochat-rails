require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :channels, :dependent => :destroy, :order => 'id'
  has_many :memberships, :dependent => :destroy
  has_many :groups, :through => :memberships

  Channel::Protocols.each do |protocol|
    has_many "#{protocol.to_channel.name.tableize}"

    class_eval %Q(
      def #{protocol.to_channel.name.tableize.singularize}
        #{protocol.to_channel.name.tableize}.first
      end
    )
  end

  validates :login, :presence => true, :length => {:minimum => 3}
  validates :login_downcase, :presence => true, :uniqueness => true, :if => :login_changed?
  validate :login_not_a_command
  validates :password, :presence => true, :unless => :created_from_invite?
  validates_confirmation_of :password, :unless => lambda { password_confirmation.nil? }

  belongs_to :default_group, :class_name => 'Group'
  before_validation :update_login_downcase
  before_save :update_location_reported_at
  before_save :encode_password, :if => :password_changed?

  data_accessor :groups_count, :default => 0
  data_accessor :locale, :default => :en

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
    users = User.find_by_login login
    users = users ? [users] : Channel.includes(:user).find_all_by_address(login).map(&:user)
    users.each do |user|
      return user if user.authenticate password
    end

    nil
  end

  def authenticate(password)
    salt = self.password[0 .. 24]
    encoded_password = self.class.hash_password salt, password
    encoded_password == self.password[24 .. -1] ? self : nil
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

  def belongs_to?(group)
    Membership.where('user_id = ? and group_id = ?', self.id, group.id).exists?
  end

  def coords=(array)
    self.lat = array.first
    self.lon = array.second
  end

  def location_known?
    self.lat && self.lon
  end

  def location_info
    str = "lat: #{self.lat.to_lat}, lon: #{self.lon.to_lon}"
    str << ", url: #{self.location_short_url}" if self.location_short_url.present?
    str
  end

  def active_channels
    if self.channels.loaded?
      self.channels.select &:active?
    else
      self.channels.where('status = ?', :on)
    end
  end

  def is_blocked_in?(group)
    group.blocked_users.try(:include?, self.id)
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

  def login_not_a_command
    errors.add(:login, 'is a reserved name') if login.try(:command?)
  end
end
