class ChannelsController < ApplicationController
  before_filter :get_channel, :only => [:show, :activate, :send_activation_code, :turn_on, :turn_off, :destroy]

  def index
    @channels = @user.channels.all
  end

  def show
  end

  def new_email
    @channel = EmailChannel.new
  end

  def create_email
    @channel = @user.email_channels.new :address => params[:email_channel][:address], :status => :pending
    if !@channel.save
      render 'new_email'
    else
      flash[:notice] = "An email has been sent to #{@channel.address}"
      redirect_to channel_path(@channel)
    end
  end

  def new_mobile_phone
    nuntium = Nuntium.new_from_config

    @channel = SmsChannel.new
    @countries = nuntium.countries
    @carriers = nuntium.carriers @countries.first['iso2']
  end

  def create_mobile_phone
    @channel = @user.sms_channels.new :address => params[:sms_channel][:address], :status => :pending
    @channel.country = params[:sms_channel][:country]
    @channel.carrier = params[:sms_channel][:carrier]
    if !@channel.save
      render 'new_mobile_phone'
    else
      flash[:notice] = "A message has been sent to #{@channel.address}"
      redirect_to channel_path(@channel)
    end
  end

  def activate
    if !@channel.activate params[:activation_code]
      render 'show' and return
    end

    @channel.turn :on
    flash[:notice] = "Your #{@channel.protocol_name} channel for #{@channel.address} is now active"
    redirect_to channels_path
  end

  def send_activation_code
    @channel.send_activation_code
    flash[:notice] = "Activation code sent to #{@channel.address}"
    redirect_to channel_path(@channel)
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