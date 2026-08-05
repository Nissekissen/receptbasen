class GroupsController < ApplicationController
  allow_unauthenticated_access only: %i[show join]

  def index
    @groups = Current.user.groups
  end

  def new
    @group = Group.new
  end

  def create
    @group = Current.user.owned_groups.new(group_params)

    if @group.save
      @group.memberships.create!(user: Current.user, admin: true)
      @group.collections.create!(user: Current.user, locked: true, name: "Favoriter")
      redirect_to @group
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @group = Group.find(params[:id])
    logged_in = authenticated?
    raise ActiveRecord::RecordNotFound if !@group.public? && (!logged_in || !@group.member?(Current.user))

    @recipes = Recipe.where(id: SavedRecipe.where(collection_id: @group.collections.select(:id)).select(:recipe_id))
    @recipes = @recipes.where(id: SavedRecipe.where(collection_id: params[:collection_id]).select(:recipe_id)) if params[:collection_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:maltidstyp_tag_id]).select(:recipe_id)) if params[:maltidstyp_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kok_tag_id]).select(:recipe_id)) if params[:kok_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kost_tag_id]).select(:recipe_id)) if params[:kost_tag_id].present?

    @collections = @group.collections
    @maltidstyp_tags = Tag.maltidstyp.order(:name)
    @kok_tags = Tag.kok.order(:name)
    @kost_tags = Tag.kost.order(:name)

    @attributions = SavedRecipe.where(recipe_id: @recipes.select(:id), collection_id: @collections.select(:id))
                               .order(:created_at)
                               .includes(:user, :collection)
                               .group_by(&:recipe_id)
                               .transform_values(&:first)
  end

  def edit
    @group = Group.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @group.member?(Current.user)
  end

  def update
    @group = Group.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @group.manager?(Current.user)

    if @group.update(group_update_params)
      redirect_to edit_group_path(@group), notice: "Namnet ändrades."
    else
      redirect_to edit_group_path(@group), alert: "Det gick inte att byta namn på gruppen."
    end
  end

  def destroy
    group = Group.find(params[:id])
    raise ActiveRecord::RecordNotFound unless Current.user == group.owner

    group.destroy
    redirect_to groups_path, notice: "Gruppen togs bort."
  end

  def join
    @group = Group.find(params[:id])
    invite = @group.invites.find_by(token: params[:token])
    raise ActiveRecord::RecordNotFound unless @group.public? || invite&.active?

    unless authenticated?
      session[:return_to_after_authenticating] = group_path(@group)
      session[:pending_group_join_id] = @group.id
      session[:pending_group_join_token] = params[:token]
      return redirect_to login_path
    end

    @group.memberships.find_or_create_by!(user: Current.user)
    redirect_to @group
  end

  private

  def group_params
    params.expect(group: [ :name, :public ])
  end

  def group_update_params
    params.expect(group: [ :name ])
  end
end
