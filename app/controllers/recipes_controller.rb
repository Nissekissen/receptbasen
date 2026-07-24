class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[show create destroy]

  def show
    @recipe = Recipe.find(params[:id])
    return request_authentication if @recipe.done? && !authenticated?

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
    @recipes = Current.user.recipes.distinct
  end

  def destroy
    Recipe.find(params[:id]).destroy
    redirect_to root_path
  end
end
