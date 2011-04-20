class UsersController < ApplicationController
  def change_password
  end

  def update_password
    @user.old_password = params[:user][:old_password]
    if !@user.authenticate(@user.old_password)
      @user.errors.add(:old_password, 'should be the same as your current one')
      render :change_password and return
    end

    [:password, :password_confirmation].each do |key|
      @user.send "#{key}=", params[:user][key]
    end

    if !@user.save
      render :change_password and return
    end

    flash[:notice] = 'Your password was changed'
    redirect_to root_path
  end
end
