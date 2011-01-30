class NuntiumController < ApplicationController
  before_filter :authenticate

  def receive_at
    pipeline = Pipeline.new
    pipeline.process params.reject{|k, v| k == 'action' || k == 'controller'}

    nuntium = Nuntium.new_api_from_config

    pipeline.messages.each do |target, messages|
      messages.each do |message|
        nuntium.send_ao :from => 'geochat://system', :to => target, :body => message
      end
    end

    Message.create_from_hash pipeline.saved_message

    head :ok
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == NuntiumConfig['incoming_username'] && password == NuntiumConfig['incoming_password']
    end
  end
end
