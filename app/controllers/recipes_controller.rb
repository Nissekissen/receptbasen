class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[show create]

  def show
    @recipe = Recipe.find(params[:id])
    return request_authentication if @recipe.done? && !authenticated?
  end

  def create
    existing = Recipe.find_by(source_url: params[:url])
    return redirect_to existing if existing

    recipe = Recipe.create!(source_url: params[:url], status: :pending)
    ParseRecipeJob.set(wait: 1.second).perform_later(recipe.id)
    redirect_to recipe
  end

  def index
    @recipes = Recipe.all
  end
end
