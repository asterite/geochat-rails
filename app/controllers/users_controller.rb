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

  def change_location
  end

  def update_location
    @user.lat = params[:user][:lat]
    @user.lon = params[:user][:lon]

    result = Geokit::Geocoders::GoogleGeocoder.reverse_geocode([@user.lat, @user.lon])
    if result.success?
      @user.location = result.full_address
      @user.location_short_url = Googl.shorten "http://maps.google.com/?q=#{@user.lat},#{@user.lon}"
    end

    @user.save!

    flash[:notice] = "Location successfully updated to #{@user.location}"
    redirect_to user_path
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
