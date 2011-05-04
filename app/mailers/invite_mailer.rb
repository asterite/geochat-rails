class InviteMailer < ActionMailer::Base
  default :from => "geochat-no-reply@instedd.org"

  def invite_email(invite)
    @invite = invite
    mail(:to => invite.user.login,
         :subject => "#{invite.requestor.login} has invited you to GeoChat group #{@invite.group}")
  end
end
