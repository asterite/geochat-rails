class ApplicationController < ActionController::Base
  protect_from_forgery

  def check_login
    if !session[:user_id]
      render :template => 'home/login'
      return
    end

    @user_id = session[:user_id]
    @user = User.find_by_id @user_id
    if !@user
      session.delete :user_id
      render :template => 'home/login'
      return
    end
  end
end
