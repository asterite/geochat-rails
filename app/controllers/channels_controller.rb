class ChannelsController < ApplicationController
  def index
  end

  def new_email
  end

  def create_email
    channel = @user.email_channels.create! :address => params[:channel][:email], :status => :pending

    flash[:notice] = "An email has been sent to #{channel.address}"
    redirect_to channels_path
  end

  def activate_email
    channel = @user.email_channels.find_by_id_and_confirmation_code params[:id], params[:code]
    if channel
      channel.turn :on
      flash[:notice] = "Your email channel for #{channel.address} is now active"
    else
      flash[:notice] = "The confirmation code for activating the email is wrong"
    end
    redirect_to channels_path
  end
end
