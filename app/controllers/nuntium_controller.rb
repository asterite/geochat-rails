class NuntiumController < ApplicationController
  before_filter :authenticate

  def receive_at
    pipeline = Pipeline.new

    begin
      pipeline.process params.reject{|k, v| k == 'action' || k == 'controller'}

      Message.create_from_hash pipeline.saved_message

      pipeline.messages.each do |message|
        message[:from] = 'geochat://system'
      end

      render :json => pipeline.messages
    rescue Exception => e
      render :text => "You've just spotted a bug: #{e.message}"
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == Nuntium::Config['incoming_username'] && password == Nuntium::Config['incoming_password']
    end
  end
end
