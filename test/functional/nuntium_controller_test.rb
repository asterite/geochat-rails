require 'test_helper'

class NuntiumControllerTest < ActionController::TestCase
  test "receive at" do
    pipeline = mock('pipeline')
    Pipeline.expects(:new).returns(pipeline)
    pipline.exepcts(:process).with('sms://1', 'Hello!')
    pipline.expects(:messages).returns({
      'sms://1' => ['Hello', 'Bye'],
      'sms://2' => ['Cool']
    })

    get :receive_at, {:from => 'sms://1', :to => 'sms://2', :body => "Hello!"}
  end
end
