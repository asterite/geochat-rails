class HomeController < ApplicationController
  before_filter :set_selected_tab

  def index
    @channels = @user.channels.all
    @active_channels = @channels.select &:active?
  end

  private

  def set_selected_tab
    @selected_tab = :root
  end
end
