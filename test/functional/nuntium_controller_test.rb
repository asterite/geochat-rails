require 'test_helper'

class NuntiumControllerTest < ActionController::TestCase
  test "receive at" do
    Node.process :from => 'sms://1', :body => '.name User1'
    Node.process :from => 'sms://1', :body => 'create Group1'
    Node.process :from => 'sms://2', :body => '.name User2'
    Node.process :from => 'sms://2', :body => 'join Group1'

    message = {'from' => 'sms://1', 'body' => "@User2 Hello!"}

    @request.env['HTTP_AUTHORIZATION'] = http_auth(Nuntium::Config['incoming_username'], Nuntium::Config['incoming_password'])
    get :receive_at, message

    assert_response :ok

    assert_equal [{:group => 'Group1', :from => 'sms://1', :to => 'sms://2', :body => 'User1 only to you: Hello!'}].to_json, @response.body

    messages = Message.all
    assert_equal 1, messages.count

    msg = messages.first
    assert_equal User.find_by_login('User1'), msg.sender
    assert_equal [User.find_by_login('User2').id], msg.data[:receivers]
    assert_equal Group.find_by_alias('Group1'), msg.group
    assert_equal 'Hello!', msg.text
  end

  test "receive at unauthorized" do
    get :receive_at

    assert_response :unauthorized
  end
end
