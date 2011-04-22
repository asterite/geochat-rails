class HomeController < ApplicationController
  before_filter :set_selected_tab

  def index
    @last_messages = @user.last_messages.all
  end

  private

  def set_selected_tab
    @selected_tab = :root
  end
end
