class GroupInvitesController < ApplicationController
  before_action :set_group
  before_action :require_manager, only: %i[index new create destroy]

  def index
    @invites = @group.invites.where(revoked_at: nil).order(:created_at)
  end

  def new
    @invite = Invite.new
  end

  def create
    @group.invites.create!(created_by: Current.user)

    redirect_to group_invites_path(@group), notice: "Länken skapades. Tryck för att kopiera."
  end

  def destroy
    invite = @group.invites.find(params[:id])
    invite.revoke!

    redirect_to group_invites_path(@group), notice: "Länken återkallades."
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def require_manager
    raise ActiveRecord::RecordNotFound unless @group.manager?(Current.user)
  end
end
