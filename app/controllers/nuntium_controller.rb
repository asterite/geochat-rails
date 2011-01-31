class NuntiumController < ApplicationController
  before_filter :authenticate

  def receive_at
    pipeline = Pipeline.new
    nuntium = Nuntium.new_api_from_config

    begin
      pipeline.process params.reject{|k, v| k == 'action' || k == 'controller'}

      pipeline.messages.each do |target, messages|
        messages.each do |message|
          nuntium.send_ao :from => 'geochat://system', :to => target, :body => message
        end
      end

      Message.create_from_hash pipeline.saved_message

      head :ok
    rescue Exception => e
      nuntium.send_ao :from => 'geochat://system', :to => params[:from], :body => "You've just spotted a bug: #{e.message}"

      head :ok
    end
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == NuntiumConfig['incoming_username'] && password == NuntiumConfig['incoming_password']
    end
  end
end
