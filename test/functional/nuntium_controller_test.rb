require 'test_helper'

class NuntiumControllerTest < ActionController::TestCase
  test "receive at" do
    message = {'from' => 'sms://1', 'body' => "Hello!"}

    pipeline = mock('pipeline')
    Pipeline.expects(:new).returns(pipeline)
    pipeline.expects(:process).with(message)
    pipeline.expects(:messages).returns({
      'sms://2' => ['Bye'],
    })

    nuntium = mock('nuntium')
    Nuntium.expects(:new).with(NuntiumConfig['url'], NuntiumConfig['account'], NuntiumConfig['application'], NuntiumConfig['password']).returns(nuntium)
    nuntium.expects(:send_ao).with({:from => 'geochat://system', :to => 'sms://2', :body => 'Bye'})

    @request.env['HTTP_AUTHORIZATION'] = http_auth(NuntiumConfig['incoming_username'], NuntiumConfig['incoming_password'])
    get :receive_at, message

    assert_response :ok
  end

  test "receive at unauthorized" do
    get :receive_at

    assert_response :unauthorized
  end
end
