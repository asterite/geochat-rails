class MessagesController < ApplicationController
  def index
    @groups = @user.sorted_groups
  end

  def show
    @msg = Message.find params[:id]
    @messages = @msg.generated_messages
  end
end
