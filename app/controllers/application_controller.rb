class ApplicationController < ActionController::Base
  protect_from_forgery

  def check_login
    redirect_to new_session_path and return unless session[:user_id]

    @user_id = session[:user_id]
    @user = User.find_by_id @user_id
    if !@user
      session.delete :user_id
      redirect_to new_session_path and return
    end
  end
end
