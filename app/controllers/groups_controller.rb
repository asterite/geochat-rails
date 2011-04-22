class GroupsController < ApplicationController
  def index
    @groups = @user.groups.includes(:memberships).all
    @owned_groups = @groups.select{|g| g.owners.include? @user}
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
