require 'cgi'

class Geocoder
  # Returns a hash with :lat, :lon and :location.
  # Returns nil if the location could not be found.
  def self.locate(location)
    results = map(location)
    return nil if results.empty?
    result = results.first
    loc = result['geometry']['location']
    {
      :lat => loc['lat'],
      :lon => loc['lng'],
      :location => result['formatted_address']
    }
  end

  def self.reverse(coords)
    results = map(coords.join ',')
    results.first['formatted_address']
  end

  def self.map(address)
    request = JSON.parse(HTTParty.get("http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape address}&sensor=false").body)
    request['results']
  end
end
