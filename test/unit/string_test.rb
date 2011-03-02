require 'test_helper'

class StringTest < ActiveSupport::TestCase
  test "shorten_urls no urls" do
    s = "hello"
    s.shorten_urls!
    assert_equal "hello", s
  end

  test "shorten one url" do
    s = "Visit http://geochat.instedd.org for more information"

    Googl.expects(:shorten).with('http://geochat.instedd.org').returns('http://short.url')

    s.shorten_urls!

    assert_equal 'Visit http://short.url for more information', s
  end

  test "shorten two urls" do
    s = "Visit http://geochat.instedd.org and http://nuntium.instedd.org for more information"

    Googl.expects(:shorten).with('http://geochat.instedd.org').returns('http://short.url')
    Googl.expects(:shorten).with('http://nuntium.instedd.org').returns('http://another.url')

    s.shorten_urls!

    assert_equal 'Visit http://short.url and http://another.url for more information', s
  end

  test "shorten one url before comma" do
    s = "Visit http://geochat.instedd.org, and start chatting!"

    Googl.expects(:shorten).with('http://geochat.instedd.org').returns('http://short.url')

    s.shorten_urls!

    assert_equal 'Visit http://short.url, and start chatting!', s
  end

  test "shorten one url before dot" do
    s = "Visit http://geochat.instedd.org... Yeah..."

    Googl.expects(:shorten).with('http://geochat.instedd.org').returns('http://short.url')

    s.shorten_urls!

    assert_equal 'Visit http://short.url... Yeah...', s
  end
end
