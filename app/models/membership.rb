class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  attr_reader_as_symbol :role

  def change_role_to(role)
    return false if self.role == role

    self.role = role
    self.save!
    true
  end
end
