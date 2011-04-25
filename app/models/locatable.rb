module Locatable
  def self.included(klass)
    klass.has_many :custom_locations, :as => :locatable
    klass.data_accessor :custom_locations_count, :default => 0
  end

  def location_known?
    self.lat && self.lon
  end

  def coords=(array)
    self.lat = array.first
    self.lon = array.second
  end

  def coords
    [lat, lon]
  end

  def has_custom_locations?
    custom_locations_count > 0
  end

  def find_custom_location(name)
    return nil unless has_custom_locations?

    custom_locations.find_by_name name
  end
end
