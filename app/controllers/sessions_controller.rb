class SessionsController < ApplicationController
  skip_before_filter :check_login, :except => [:destroy]

  def new
    @user = User.new
    @new_user = User.new
  end

  def create
    @user = User.authenticate params[:user][:login], params[:user][:password]
    if !@user
      @user = User.new :login => params[:user][:login]
      @new_user = User.new

      flash[:login_error] = 'Invalid login/passowrd'
      render :new and return
    end

    if params[:user][:remember_me_token] == '1'
      @user.remember_me_token = Guid.new.to_s
      @user.save!

      cookies[:remember_me] = {:value => "#{@user.id}|#{@user.remember_me_token}", :expires => 30.days.from_now }
    end

    flash[:login_error] = nil
    session[:user_id] = @user.id
    redirect_to root_path
  end

  def register
    @new_user = User.new params[:user]
    if !@new_user.save
      @user = User.new
      render :new and return
    end

    session[:user_id] = @new_user.id
    redirect_to root_path
  end

  def destroy
    cookies.delete :remember_me
    session.delete :user_id
    redirect_to root_path
  end
end
