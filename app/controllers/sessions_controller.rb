class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    return redirect_to root_path unless params[:user]

    @user = User.authenticate params[:user][:login], params[:user][:password]
    if @user
      flash[:login_error] = nil
      session[:user_id] = @user.id
      redirect_to root_path
    else
      @user = User.new :login => params[:user][:login]

      flash[:login_error] = 'Invalid login/passowrd'
      render :new
    end
  end

  def destroy
    session.delete :user_id
    redirect_to root_path
  end
end
