class ApiController < ApplicationController
  skip_before_filter :check_login
  before_filter :authenticate, :except => [:create_user, :user, :verify_user_credentials]
  before_filter :check_group, :only => [:group, :group_members, :group_messages]

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
    render :json => @user.groups
  end

  def group
    render :json => @group
  end

  def group_members
    render :json => @group.users
  end

  def group_messages
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i
    offset = (page - 1) * per_page
    render :json => {:items => @group.messages.order('created_at DESC').offset(offset).limit(per_page)}
  end

  private

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      @user = User.authenticate username, password
    end
  end

  def check_group
    @group = Group.find_by_alias params[:alias]
    return head :not_found unless @group
    return head :unauthorized unless @user.belongs_to? @group
  end
end
