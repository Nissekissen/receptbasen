class InvitesController < ApplicationController
  allow_unauthenticated_access

  def show
    @invite = Invite.find_by(token: params[:token])
    return if @invite.nil? || !@invite.active?

    @group = @invite.group
    logged_in = authenticated?

    redirect_to @group if logged_in && @group.member?(Current.user)
  end
end
