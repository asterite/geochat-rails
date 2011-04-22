class GroupsController < ApplicationController
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
    if @group.save
      @user.join @group, :as => :owner

      flash[:notice] = "Group #{@group.alias} created"
      redirect_to groups_path
    else
      render :new
    end
  end

  def show
    @group = Group.find_by_alias params[:id]
    @memberships = @group.memberships.includes(:user)
  end

  def join
    @group = Group.find_by_alias params[:id]
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
end
