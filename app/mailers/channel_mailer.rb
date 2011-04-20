class ChannelMailer < ActionMailer::Base
  default :from => "geochat-no-reply@instedd.org"

  def activation_email(channel)
    @channel = channel
    @user = channel.user
    mail(:to => channel.address,
         :subject => "Activation of your email channel")
  end
end
