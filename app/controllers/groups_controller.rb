class GroupsController < ApplicationController
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

  private

  def group_params
    params.expect(group: [ :name, :public ] )
  end

end
