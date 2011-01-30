class ApiController < ApplicationController
  def create_user
    user = User.create! :login => params[:login], :password => params[:password], :display_name => params[:displayname]
    render :json => user
  rescue
    head :bad_request
  end

  def user
    user = User.find_by_login params[:login]
    return head :not_found unless user
    render :json => user
  end

  def verify_user_credentials
    render :text => (!!User.authenticate(params[:login], params[:password])).to_s
  end
end
