class MessagesController < ApplicationController
  def index
    @groups = @user.groups
  end
end
