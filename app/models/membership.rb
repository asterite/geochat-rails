class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  attr_reader_as_symbol :role
end
