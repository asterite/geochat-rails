class MessagesController < ApplicationController
  def index
    @groups = @user.sorted_groups
  end
end
