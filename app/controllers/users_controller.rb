class UsersController < ApplicationController
  before_filter { @selected_tab = :user }
  before_filter :add_old_password_accessor, :only => [:change_password, :update_password]

  def index
    @pagination = {
      :page => params[:custom_locations_page] || 1,
      :per_page => 10
    }
    @custom_locations = @user.custom_locations.paginate @pagination
  end

  def show
    @other_user = User.find_by_login params[:id]
    @memberships = @user.visible_memberships_of @other_user
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

  include LocatableActions
  def locatable; @user; end
  def locatable_path; user_path; end

  private

  def add_old_password_accessor
    def @user.old_password=(value); end;
    def @user.old_password; end;
  end
end
