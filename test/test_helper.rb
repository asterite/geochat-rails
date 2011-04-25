ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require File.expand_path(File.dirname(__FILE__) + '/blueprints')
require 'mocha'
require 'base64'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  include Mocha::API

  def http_auth(user, pass)
    'Basic ' + Base64.encode64(user + ':' + pass)
  end

  def login(user)
    session[:user_id] = user.id
    user
  end

  def expect_locate(name, lat, lon, location)
    obj = stub(:lat => lat, :lng => lon, :full_address => location, :success? => true)
    Geokit::Geocoders::GoogleGeocoder.expects(:geocode).with(name).returns(obj)
  end

  def expect_locate_not_found(name)
    obj = stub(:success? => false)
    Geokit::Geocoders::GoogleGeocoder.expects(:geocode).with(name).returns(obj)
  end

  def expect_reverse(lat, lon, location)
    obj = stub(:full_address => location, :success? => true)
    Geokit::Geocoders::GoogleGeocoder.expects(:reverse_geocode).with([lat, lon]).returns(obj)
  end

  def expect_reverse_not_found(lat, lon)
    obj = stub(:success? => false)
    Geokit::Geocoders::GoogleGeocoder.expects(:reverse_geocode).with([lat, lon]).returns(obj)
  end

  def expect_shorten(long_url, short_url)
    Googl.expects(:shorten).with(long_url).returns(short_url)
  end

  def expect_shorten_google_maps(*params)
    if params.length == 3
      expect_shorten "http://maps.google.com/?q=#{params[0]},#{params[1]}", params[2]
    elsif params.length == 2
      expect_shorten "http://maps.google.com/?q=#{CGI.escape params[0]}", params[1]
    else
      raise "Expected 2 or 3 params for expect_shorten_google_maps"
    end
  end
end
