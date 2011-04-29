class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :check_login

  def check_login
    check_user_in_session or check_user_used_remember_me or go_to_login
  end

  private

  def check_user_in_session
    return false unless session[:user_id]

    @user_id = session[:user_id]
    @user = User.find_by_id @user_id
    if @user
      true
    else
      session.delete :user_id
      false
    end
  end

  def check_user_used_remember_me
    return false unless cookies[:remember_me].present?

    user_id, remember_me_token = cookies[:remember_me].split '|', 2
    return false unless user_id && remember_me_token

    user = User.find_by_id user_id
    return false unless user && user.remember_me_token.present? && user.remember_me_token == remember_me_token

    @user_id = user_id
    @user = user
    session[:user_id] = @user_id
    true
  end

  def go_to_login
    session[:url_after_login] = request.fullpath
    redirect_to new_session_path
  end

end
