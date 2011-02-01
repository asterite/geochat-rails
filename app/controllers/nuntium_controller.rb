class NuntiumController < ApplicationController
  before_filter :authenticate

  def receive_at
    pipeline = Pipeline.new

    begin
      pipeline.process params.reject{|k, v| k == 'action' || k == 'controller'}

      Message.create_from_hash pipeline.saved_message

      answer = []
      pipeline.messages.each do |target, messages|
        messages.each do |message|
          answer << {:from => 'geochat://system', :to => target, :body => message}
        end
      end

      render :json => answer
    rescue Exception => e
      render :text => "You've just spotted a bug: #{e.message}"
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == NuntiumConfig['incoming_username'] && password == NuntiumConfig['incoming_password']
    end
  end
end
