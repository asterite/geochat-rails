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

  setup do
    ActionMailer::Base.deliveries = []
  end

  def http_auth(user, pass)
    @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64.encode64(user + ':' + pass)
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
      Googl.expects(:shorten_location).with(params[0 .. 1]).returns(params[2])
    elsif params.length == 2
      Googl.expects(:shorten_location).with(params[0]).returns(params[1])
    else
      raise "Expected 2 or 3 params for expect_shorten_google_maps"
    end
  end

  def assert_message_saved(user, group, text)
    messages = Message.all
    assert_equal 1, messages.length
    message = messages.first
    if user.is_a? User
      assert_equal user, message.sender
    else
      assert_equal user, message.sender.login
    end
    if group.is_a? Group
      assert_equal group, message.group
    else
      assert_equal group, message.group.alias
    end
    assert_equal text, message.text
    message
  end

  def assert_message_saved_with_location(user, group, text, location, lat, lon, short_url)
    message = assert_message_saved(user, group, text)
    assert_equal location, message.location
    assert_in_delta lat, message.lat, 1e-07
    assert_in_delta lon, message.lon, 1e-07
    assert_equal short_url, message.location_short_url
  end
end
