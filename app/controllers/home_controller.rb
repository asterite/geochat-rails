class HomeController < ApplicationController
  before_filter { @selected_tab = :root }

  def index
    @last_messages = @user.last_messages.all
    @has_groups = @user.groups_count > 0
    @has_channels = @user.channels.exists?
    @has_location = @user.location_known?
  end
end
