class GroupsController < ApplicationController
  def index
    @memberships = @user.memberships.includes(:group).all
    @groups = @memberships.map &:group
    @owned_groups = @memberships.select{|m| m.role == :owner}.map &:group
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
end
