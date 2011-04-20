class ChannelsController < ApplicationController
  before_filter :get_channel, :only => [:activate_email, :turn_on, :turn_off, :destroy]

  def index
    @channels = @user.channels.all
  end

  def new_email
    @channel = EmailChannel.new
  end

  def create_email
    @channel = @user.email_channels.new :address => params[:email_channel][:address], :status => :pending
    if !@channel.save
      flash[:notice] = 'You already configured foo@bar.com as an email channel'
      render 'new_email'
    else
      flash[:notice] = "An email has been sent to #{@channel.address}"
      redirect_to channels_path
    end
  end

  def activate_email
    if @channel.activate params[:code]
      @channel.turn :on
      flash[:notice] = "Your email channel for #{@channel.address} is now active"
    else
      flash[:notice] = "The confirmation code for activating the email is wrong"
    end
    redirect_to channels_path
  end

  [:on, :off].each do |status|
    define_method "turn_#{status}" do
      if @channel.status != :pending
        @channel.turn status
        flash[:notice] = "Channel #{@channel.address} turned #{status}"
      end

      redirect_to channels_path
    end
  end

  def destroy
    @channel.destroy

    flash[:notice] = "Channel #{@channel.address} deleted"
    redirect_to channels_path
  end

  private

  def get_channel
    @channel = @user.channels.find params[:id]
  end
end
