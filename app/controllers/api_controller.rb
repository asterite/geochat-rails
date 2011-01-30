class ApiController < ApplicationController
  before_filter :authenticate, :only => [:user_groups]

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

  def user_groups
    render :json => {:items => @user.groups}
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @user = User.authenticate username, password
    end
  end
end
