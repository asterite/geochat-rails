require 'test_helper'

class CustomLocationTest < ActiveSupport::TestCase
  test "increment user custom locations count on save" do
    Geokit::Geocoders::GoogleGeocoder.expects(:reverse_geocode).returns(stub(:success? => false))
    Googl.expects(:shorten_location).returns('http://short.url')

    user = User.make
    assert_equal 0, user.custom_locations_count

    user.custom_locations.create! :name => 'foo'

    user.reload
    assert_equal 1, user.custom_locations_count
  end

  test "decrement user custom locations count on destroy" do
    Geokit::Geocoders::GoogleGeocoder.expects(:reverse_geocode).returns(stub(:success? => false))
    Googl.expects(:shorten_location).returns('http://short.url')

    user = User.make
    loc = user.custom_locations.create! :name => 'foo'
    loc.destroy

    user.reload
    assert_equal 0, user.custom_locations_count
  end
end
