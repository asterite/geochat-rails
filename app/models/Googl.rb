module Googl
  Key = YAML.load_file(File.expand_path('../../../config/googl.yml', __FILE__))[Rails.env]['key']

  def self.shorten(url)
    body = (HTTParty.post "https://www.googleapis.com/urlshortener/v1/url?key=#{Key}", :headers => {'Content-Type' => 'application/json'}, :body => {:longUrl => url}.to_json).body
    json = JSON.parse body
    json['id']
  end

  def self.shorten_location(location)
    if location.is_a? Array
      shorten "http://maps.google.com/?q=#{location[0]},#{location[1]}"
    else
      shorten "http://maps.google.com/?q=#{CGI.escape location}"
    end
  end
end
