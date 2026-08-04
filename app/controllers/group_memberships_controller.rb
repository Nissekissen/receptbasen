class GroupMembershipsController < ApplicationController
  before_action :set_group
  before_action :set_membership, only: %i[update destroy]

  def index
    raise ActiveRecord::RecordNotFound unless @group.member?(Current.user)

    @memberships = @group.memberships.includes(:user).order(admin: :desc, created_at: :asc)
  end

  # Toggles admin on/off. Owner-only — promoting/demoting other admins is
  # deliberately not something a non-owner admin can do.
  def update
    raise ActiveRecord::RecordNotFound unless Current.user == @group.owner
    raise ActiveRecord::RecordNotFound if @membership.user == @group.owner

    @membership.update!(admin: !@membership.admin?)
    redirect_to group_memberships_path(@group)
  end

  # Owner and admins have equal power to remove a regular member, but neither
  # can remove the owner — the only way out of ownership is deleting the group.
  def destroy
    raise ActiveRecord::RecordNotFound unless @group.manager?(Current.user)
    raise ActiveRecord::RecordNotFound if @membership.user == @group.owner

    @membership.destroy
    redirect_to group_memberships_path(@group)
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_membership
    @membership = @group.memberships.find(params[:id])
  end
end
