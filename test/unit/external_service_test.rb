# coding: utf-8

require 'unit/node_test'

class ExternalServiceTest < NodeTest
  setup do
    create_users 1..2
    send_message 1, "create Group1"
    send_message 2, "join Group1"

    group = Group.find_by_alias 'Group1'
    group.external_service_url = 'http://example.com'
    group.save!

    @options = {:from => 'sms://1', :to => 'geochat://system', :sender => 'User1'}
  end

  test "external service stop" do
    HTTParty.expects(:post).with("http://example.com?#{@options.to_query}", :body => 'something').returns(stub(:headers => {'x-geochat-action' => 'stop'}))

    send_message 1, "something"
    assert_no_messages_sent_to 2
    assert_no_messages_saved
  end
end
