class HomeController < ApplicationController
  before_filter :set_selected_tab

  def index
    @last_messages = @user.last_messages.all
    @has_groups = @user.groups_count > 0
    @has_channels = @user.channels.exists?
    @has_location = @user.location_known?
  end

  private

  def set_selected_tab
    @selected_tab = :root
  end
end
