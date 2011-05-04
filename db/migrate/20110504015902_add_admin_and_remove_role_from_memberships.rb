class AddAdminAndRemoveRoleFromMemberships < ActiveRecord::Migration
  class Membership < ActiveRecord::Base; end

  def self.up
    add_column :memberships, :admin, :boolean, :default => false

    Membership.all.each do |m|
      m.admin = m.role == 'admin' || m.role == 'owner'
      m.save!
    end

    remove_column :memberships, :role
  end

  def self.down
    add_column :memberships, :role, :string

    Membership.all.each do |m|
      m.role = m.admin? ? :owner : :member
      m.save!
    end

    remove_column :memberships, :admin
  end
end
