# coding: utf-8

require 'unit/pipeline_test'

class LogoutTest < PipelineTest
  test "logout" do
    send_message "sms://1", ".name Ary Manzana"

            Send(1, "#bye");
            AssertUserIsLoggedOff(1);
            AssertMessageSentToPhone(1, "Ary Manzana, this device has been removed from your account.");
            AssertNoSentMessagesLeft();
            AssertNoSavedMessages();
  end
end
