class SessionsController < ApplicationController
  skip_before_filter :check_login, :except => [:destroy]

  def new
    @user = User.new
    @new_user = User.new
    @invite = Invite.find_by_id session[:invite_id] if session[:invite_id]
  end

  def create
    @user = User.authenticate params[:user][:login], params[:user][:password]
    if !@user
      new
      @user = User.new :login => params[:user][:login]

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

    if session[:invite_id]
      process_invite @user, :create
    else
      redirect_to(session.delete(:url_after_login).presence || root_path)
    end
  end

  def register
    @new_user = User.new params[:user]
    if !@new_user.save
      @temp_user = @new_user
      new
      @new_user = @temp_user
      render :new and return
    end

    session[:user_id] = @new_user.id
    if session[:invite_id]
      process_invite @new_user, :register
    else
      redirect_to(session.delete(:url_after_login).presence || root_path)
    end
  end

  def destroy
    clear_session
    redirect_to root_path
  end

  def activate_email
    invite = Invite.find params[:id]
    redirect_to root_path and return unless invite.user.login == params[:email] && invite.group.alias == params[:group]

    clear_session
    session[:invite_id] = invite.id
    redirect_to new_session_path
  end

  private

  def process_invite(existing_user, action)
    invite = Invite.find session.delete(:invite_id)
    user = invite.user
    group = invite.group

    existing_user.password_confirmation = nil

    already_has_channel = existing_user.email_channels.where(:address => user.login).exists?
    existing_user.email_channels.create! :address => user.login, :status => :on unless already_has_channel

    already_belongs_to_group = existing_user.belongs_to? group
    existing_user.join group unless already_belongs_to_group

    user.destroy
    invite.destroy

    if action == :register
      flash.notice = "Welcome to GeoChat and to group #{group}"
    else
      if already_belongs_to_group
        flash.notice = "You already are a member of #{group}"
      else
        flash.notice = "You are now a member of #{group}"
      end
    end
    redirect_to group
  end

  def clear_session
    cookies.delete :remember_me
    session.delete :user_id
    session.delete :url_after_login
  end
end
