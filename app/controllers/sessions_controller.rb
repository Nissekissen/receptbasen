class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      join_pending_group_for(user)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  # Completes a "Gå med" click made while logged out (see GroupsController#join) —
  # the group id was stashed in the session before bouncing here to log in.
  def join_pending_group_for(user)
    group_id = session.delete(:pending_group_join_id)
    group_token = session.delete(:pending_group_join_token)
    return unless group_id

    group = Group.find_by(id: group_id)
    return unless group

    invite = group.invites.find_by(token: group_token)
    return unless group.public? || invite&.active?
    group.memberships.find_or_create_by!(user: user)
  end
end
