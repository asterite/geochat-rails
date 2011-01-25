class Channel < ActiveRecord::Base
  belongs_to :user

  def status
    self.attributes['status'].try(:to_sym)
  end

  def full_address
    "#{protocol}://#{address}"
  end
end
