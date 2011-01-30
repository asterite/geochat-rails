class ApiController < ApplicationController
  def create_user
    user = User.create! :login => params[:login], :password => params[:password], :display_name => params[:displayname]

    render :json => user
  end
end
