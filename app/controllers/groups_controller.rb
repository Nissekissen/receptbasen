class GroupsController < ApplicationController
  def new
    @group = Group.new
  end

  def create
    @group = Current.user.owned_groups.new(group_params)

    if @group.save
      @group.memberships.create!(user: Current.user, admin: true)
      redirect_to @group
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def group_params
    params.expect(group: [ :name, :public ] )
  end

end
