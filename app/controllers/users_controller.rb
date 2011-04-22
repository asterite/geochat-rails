class UsersController < ApplicationController
  before_filter :add_old_password_accessor, :only => [:change_password, :update_password]

  def index
  end

  def change_password
  end

  def update_password
    if !@user.authenticate(params[:user][:old_password])
      @user.errors.add(:old_password, 'should be the same as your current one')
      render :change_password and return
    end

    [:password, :password_confirmation].each do |key|
      @user.send "#{key}=", params[:user][key]
    end

    if @user.save
      flash[:notice] = 'Your password was changed'
      redirect_to root_path
    else
      render :change_password
    end
  end

  private

  def add_old_password_accessor
    def @user.old_password=(value); end;
    def @user.old_password; end;
  end
end
