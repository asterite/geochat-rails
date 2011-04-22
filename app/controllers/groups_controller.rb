class GroupsController < ApplicationController
  def index
  end

  def new
    @group = @user.groups.new
  end

  def create
  end
end
