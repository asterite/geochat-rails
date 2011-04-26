class CustomChannel < ActiveRecord::Base
  belongs_to :group

  validates :name, :presence => true, :format => {:with => /\A[a-zA-Z0-9]+\Z/, :message => 'can only contain alphanumeric characters'}
  validates_presence_of :group_id
end
