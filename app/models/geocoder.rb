require 'cgi'

class Geocoder
  def self.locate(location)
    response = HTTParty.get("http://maps.google.com/maps/geo?q=#{CGI.escape location}&output=csv&key=#{GoogleConfig['maps_key']}").body
    pieces = response.split ','
    lat, lon = pieces[2].to_f, pieces[3].to_f
    lat == 0 && lon == 0 ? nil : [lat, lon]
  end

  def self.reverse(coords)
    response = HTTParty.get("http://maps.google.com/maps/geo?q=#{CGI.escape coords.join(',')}&output=csv&oe=utf8&sensor=true&key=#{GoogleConfig['maps_key']}").body
    pieces = response.split ',', 3
    location = pieces[2]
    location = location[1 ... -1]
    location.empty? ? "?" : location
  end
end
