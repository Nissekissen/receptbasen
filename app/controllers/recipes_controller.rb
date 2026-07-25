class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[new show create destroy]

  def new
  end

  def show
    @recipe = Recipe.find(params[:id])
    return request_authentication if @recipe.done? && !@recipe.published? && !authenticated?

    @collections = Current.user.collections if authenticated?
  end

  def create
    existing = Recipe.find_by(source_url: params[:url])
    return redirect_to existing if existing

    recipe = Recipe.create!(source_url: params[:url], status: :pending)
    ParseRecipeJob.set(wait: 1.second).perform_later(recipe.id)
    redirect_to recipe
  end

  def index
    @recipes = Recipe.where(id: Current.user.saved_recipes.select(:recipe_id))
    @recipes = @recipes.where(id: SavedRecipe.where(collection_id: params[:collection_id]).select(:recipe_id)) if params[:collection_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:maltidstyp_tag_id]).select(:recipe_id)) if params[:maltidstyp_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kok_tag_id]).select(:recipe_id)) if params[:kok_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kost_tag_id]).select(:recipe_id)) if params[:kost_tag_id].present?

    @collections = Current.user.collections
    @maltidstyp_tags = Tag.maltidstyp.order(:name)
    @kok_tags = Tag.kok.order(:name)
    @kost_tags = Tag.kost.order(:name)
  end

  def destroy
    Recipe.find(params[:id]).destroy
    redirect_to root_path
  end
end
