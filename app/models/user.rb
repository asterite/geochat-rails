require 'digest/sha1'

class User < ActiveRecord::Base
  include Locatable

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

  validates :login, :presence => true, :length => {:minimum => 3}, :format => {:with => /\A[a-zA-Z0-9]+\Z/, :message => 'can only contain alphanumeric characters'}
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
  data_accessor :groups_order, :default => 'activity'
  data_accessor :groups_order_manually
  data_accessor :remember_me_token

  def self.find_by_login(login)
    self.find_by_login_downcase login.downcase
  end
  class << self; alias_method :[], :find_by_login; end

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
  # options = :to => g
  def invite(user, options = {})
    group = options[:to] or raise "Must give a :to => group option"
    if user.kind_of?(String)
      user = User.create! :login => user, :created_from_invite => true
    end
    Invite.create! :group => group, :user => user, :admin_accepted => self.can_invite_in?(group), :requestor => self
  end

  def invite_in(group)
    Invite.where(:user_id => self.id, :group_id => group.id).first
  end

  def invites_in(group)
    Invite.where(:user_id => self.id, :group_id => group.id).all
  end

  def request_join(group)
    Invite.create! :user => self, :group => group, :user_accepted => true
  end

  def requests
    Invite.where(:user_id => id)
  end

  def others_requests
    Invite.includes(:group => :memberships).where('invites.admin_accepted = ? and memberships.user_id = ? and (memberships.role = ? or memberships.role = ?)', false, id, :admin, :owner)
  end

  def invites
    Invite.where(:requestor_id => id)
  end

  def role_in(group)
    Membership.find_by_group_id_and_user_id(group.id, self.id).try(:role).try(:to_sym)
  end

  def is_owner_of?(group)
    role_in(group) == :owner
  end

  def can_invite_in?(group)
    [:owner, :admin].include?(role_in group)
  end

  def shares_a_common_group_with?(user)
    result = self.class.connection.execute "select 1 from memberships m1, memberships m2 where m1.group_id = m2.group_id and m1.user_id = #{self.id} and m2.user_id = #{user.id}"
    result.count > 0
  end

  def membership_in(group)
    Membership.where(:user_id => self.id, :group_id => group.id).first
  end

  def belongs_to?(group)
    Membership.where(:user_id => self.id, :group_id => group.id).exists?
  end

  def messages
    Message.joins(:group => :memberships).where('memberships.user_id = ?', self.id)
  end

  def last_messages
    messages.order('messages.id DESC').limit(10)
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

  def visible_memberships_of(other_user)
    my_groups = self.groups.map &:id
    other_user_memberships = other_user.memberships.includes(:group).all
    other_user_memberships.select{|x| x.group.public? || my_groups.include?(x.group_id)}
  end

  def sorted_groups
    groups = self.groups.all
    case self.groups_order
    when 'activity'
      # TODO
    when 'alphabetically'
      groups.sort! {|x, y| x.alias_downcase <=> y.alias_downcase }
    when 'manually'
      hash = {}
      self.groups_order_manually.each_with_index { |group, i| hash[group] = i }

      groups.sort! do |x, y|
        idx_x = hash[x.alias_downcase] || 10000
        idx_y = hash[y.alias_downcase] || 10000
        idx_x <=> idx_y
      end
    end
    groups
  end

  def send_message_to_group(group, message)
    msg = create_message_for_group group, message
    group.send_message msg
  end

  def create_message_for_group(group, message, options = {})
    Message.create_from_hash({
      :sender => self,
      :group => group,
      :text => message,
      :lat => self.lat,
      :lon => self.lon,
      :location => self.location_short_url,
      :location_short_url => self.location_short_url
    })
  end

  def as_json(options = {})
    hash = {:login => self.login}
    hash[:displayName] = self.display_name if self.display_name.present?
    hash.merge! location_json
    hash[:created] = self.created_at
    hash[:updated] = self.updated_at
    hash
  end

  def to_param
    login
  end

  def to_s
    login
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
