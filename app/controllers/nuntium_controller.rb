class NuntiumController < ApplicationController
  skip_before_filter :check_login
  before_filter :authenticate, :only => [:receive_at]

  def receive_at
    User.transaction do
      render :json => Node.process(params)
    end
  end

  def carriers
    render :json => Nuntium.new_from_config.carriers(params[:iso2])
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == Nuntium::Config['incoming_username'] && password == Nuntium::Config['incoming_password']
    end
  end
end
