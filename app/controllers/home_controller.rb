class HomeController < ApplicationController
  before_filter :check_login, :except => [:login, :logout]

  def index
  end

  def login
    @user = User.authenticate params[:user][:login], params[:user][:password]
    if @user
      flash[:login_error] = nil
      session[:user_id] = @user.id
      redirect_to root_path
    else
      flash[:login_error] = 'Invalid login/passowrd'
    end
  end

  def logout
    session.delete :user_id
    redirect_to root_path
  end
end
