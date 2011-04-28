# coding: utf-8

require 'unit/node_test'

class ExternalServiceTest < NodeTest
  setup do
    create_users 1..2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    @group = Group.find_by_alias 'Group1'
    @group.external_service_url = 'http://example.com'
    @group.save!

    @options = {:from => 'sms://1', :to => 'geochat://system', :sender => 'User1'}
  end

  test "external service stop" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'stop'}, :body => nil))

    send_message 1, "something"
    assert_no_messages_sent_to 1..2
    assert_no_messages_saved
  end

  test "external service continue" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'continue'}, :body => nil))

    send_message 1, "something"
    assert_no_messages_sent_to 1
    assert_messages_sent_to 2, "User1: something", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'something'
  end

  test "external service continue and replace with" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'continue', 'x-geochat-replacewith' => 'abracadabra'}, :body => nil))

    send_message 1, "something"
    assert_no_messages_sent_to 1
    assert_messages_sent_to 2, "User1: abracadabra", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'abracadabra'
  end

  test "external service continue and replace backwards compatible" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'continue', 'x-geochat-replace' => 'true'}, :body => 'abracadabra'))

    send_message 1, "something"
    assert_no_messages_sent_to 1
    assert_messages_sent_to 2, "User1: abracadabra", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'abracadabra'
  end

  test "external service reply and stop" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'reply'}, :body => 'abracadabra'))

    send_message 1, "something"
    assert_messages_sent_to 1, "abracadabra", :group => 'Group1'
    assert_no_messages_sent_to 2
    assert_no_messages_saved
  end

  test "external service reply and continue" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'reply-and-continue'}, :body => 'abracadabra'))

    send_message 1, "something"
    assert_messages_sent_to 1, "abracadabra", :group => 'Group1'
    assert_messages_sent_to 2, "User1: something", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'something'
  end

  test "external service reply and replace" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'reply-and-continue', 'x-geochat-replacewith' => 'magic'}, :body => 'abracadabra'))

    send_message 1, "something"
    assert_messages_sent_to 1, "abracadabra", :group => 'Group1'
    assert_messages_sent_to 2, "User1: magic", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'magic'
  end

  test "external service doesn't match prefix" do
    @group.external_service_prefix = '.r'
    @group.save!

    HTTParty.expects(:post).never

    send_message 1, "something"
    assert_messages_sent_to 2, "User1: something", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', 'something'
  end

  test "external service strips prefix" do
    @group.external_service_prefix = '#r'
    @group.save!

    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'continue'}, :body => nil))

    send_message 1, "#r something"
    assert_messages_sent_to 2, "User1: #r something", :group => 'Group1'
    assert_message_saved 'User1', 'Group1', '#r something'
  end

  test "external service with location update with replace" do
    @options.merge!(:lat => 48.856667, :lon => 2.350987)
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'continue', 'x-geochat-replacewith' => 'abracadabra'}, :body => nil))

    expect_locate 'Paris', 48.856667, 2.350987, 'Paris, France'
    expect_shorten_google_maps 'Paris, France', 'http://short.url'

    send_message 1, "at Paris * something"
    assert_messages_sent_to 1, T.location_successfuly_updated('Paris, France', "lat: 48.85667 N, lon: 2.35099 E, url: http://short.url"), :group => 'Group1'
    assert_messages_sent_to 2, "User1: abracadabra (#{T.at_place 'Paris, France', 'lat: 48.85667 N, lon: 2.35099 E, url: http://short.url'})", :group => 'Group1'
    assert_user_location "User1", "Paris, France", 48.856667, 2.350987, "http://short.url"
    assert_message_saved_with_location "User1", "Group1", "abracadabra", "Paris, France", 48.856667, 2.350987, "http://short.url"
  end

end
