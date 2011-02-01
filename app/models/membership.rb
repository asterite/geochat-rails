class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  def role
    self.attributes['role'].try(:to_sym)
  end
end
