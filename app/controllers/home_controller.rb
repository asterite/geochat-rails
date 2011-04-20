class HomeController < ApplicationController
  def index
    @channels = @user.channels.all
    @active_channels = @channels.select &:active?
  end
end
