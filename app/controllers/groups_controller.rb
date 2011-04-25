class GroupsController < ApplicationController
  before_filter :get_group, :only => [:show, :join, :change_role, :new_custom_location]
  before_filter :check_is_owner, :only => [:new_custom_location]

  def index
    @memberships = @user.memberships.includes(:group).all
    @groups = @memberships.map &:group
    @owned_groups = @memberships.select{|m| m.role == :owner}.map &:group
  end

  def public
    @pagination = {
      :page => params[:page] || 1,
      :per_page => 10
    }
    @groups = Group.public.includes(:memberships).paginate @pagination
    @groups.reject! { |g| g.memberships.map(&:user_id).include? @user.id }
  end

  def new
    @group = @user.groups.new
  end

  def create
    @group = @user.groups.new params[:group]
    if @group.valid? && @group.location_known?
      result = Geokit::Geocoders::GoogleGeocoder.reverse_geocode([@group.lat, @group.lon])
      @group.location = result.full_address if result.success?
    end

    if @group.save
      @user.join @group, :as => :owner

      flash[:notice] = "Group #{@group.alias} created"
      redirect_to groups_path
    else
      render :new
    end
  end

  def show
    @memberships_pagination = {
      :page => params[:users_page] || 1,
      :per_page => 10
    }
    @memberships = @group.memberships.includes(:user).order('users.login_downcase').paginate @memberships_pagination
    @user_membership = @memberships.select{|m| m.user_id == @user.id}.first

    @custom_locations_pagination = {
      :page => params[:custom_locations_page] || 1,
      :per_page => 10
    }
    @custom_locations = @group.custom_locations.order('name').paginate @custom_locations_pagination
  end

  def join
    if @group.requires_approval_to_join?
      flash[:notice] = "This groups needs approval to join"
    elsif @user.belongs_to? @group
      flash[:notice] = "You already are a member of #{@group.alias}"
    else
      @user.join @group
      flash[:notice] = "You are now a member of #{@group.alias}"
    end

    redirect_to @group
  end

  def change_role
    user_membership = @user.membership_in(@group)
    membership = @group.memberships.joins(:user).where('users.login_downcase = ?', params[:user].downcase).first

    # Can't touch someone bigger or same than you
    return redirect_to @group if membership >= user_membership

    membership.role = params[:role].to_sym

    # Can't change to someone bigger than you
    return redirect_to @group if membership > user_membership

    membership.save!

    flash[:notice] = "User #{params[:user]} is now #{params[:role]} in #{@group}"
    redirect_to @group
  end

  def new_custom_location
    @custom_location = @group.custom_locations.new
  end

  def create_custom_location
    @custom_location = @group.custom_locations.new params[:custom_location]
    if @custom_location.save
      flash[:notice] = "Custom location #{@custom_location.name} created"
      redirect_to group_path(@group)
    else
      render :new_custom_location
    end
  end

  def destroy_custom_location
    @custom_location = @group.custom_locations.find_by_name params[:custom_location_id]
    @custom_location.destroy

    flash[:notice] = "Custom location #{@custom_location.name} deleted"
    redirect_to group_path(@group)
  end

  private

  def get_group
    @group = Group.find_by_alias params[:id]
  end

  def check_is_owner
    redirect_to group_path(@group) unless @user.is_owner_of? @group
  end
end
