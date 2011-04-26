class CustomLocation < ActiveRecord::Base
  belongs_to :locatable, :polymorphic => true

  validates :name, :presence => true, :format => {:with => /\A[a-zA-Z0-9]+\Z/, :message => 'can only contain alphanumeric characters'}
  validates_uniqueness_of :name_downcase, :scope => [:locatable_type, :locatable_id]

  before_validation :update_name_downcase
  before_save :geocode, :if => lambda { new_record? || lat_changed? || lon_changed? }
  before_save :shorten_url, :if => lambda { new_record? || lat_changed? || lon_changed? }

  before_create :increment_locatable_custom_locations_count
  after_destroy :decrement_locatable_custom_locations_count

  def to_param
    name
  end

  def self.find_by_name(name)
    self.find_by_name_downcase name.downcase
  end

  def coords
    [lat, lon]
  end

  private

  def update_name_downcase
    self.name_downcase = self.name.downcase
  end

  def geocode
    result = Geokit::Geocoders::GoogleGeocoder.reverse_geocode([lat, lon])
    self.location = result.full_address if result.success?
  end

  def shorten_url
    self.location_short_url = Googl.shorten_location coords
  end

  def increment_locatable_custom_locations_count
    self.locatable.custom_locations_count += 1
    self.locatable.save!
  end

  def decrement_locatable_custom_locations_count
    self.locatable.custom_locations_count -= 1
    self.locatable.save!
  end
end
