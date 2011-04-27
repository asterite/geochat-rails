class InvitesController < ApplicationController
  def index
    @others_requests = @user.others_requests.all
    @requests = @user.requests.all
    @invites = @user.invites.all
    @invites_from_others = @requests.select{|x| x.requestor_id && !x.user_accepted}
    @requests = @requests.select{|x| !x.requestor_id || x.user_accepted}
  end
end
