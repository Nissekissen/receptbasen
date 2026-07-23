class RecipesController < ApplicationController
  def show
    @recipe = Recipe.find(params[:id])
  end

  def create
    recipe = Recipe.create!(source_url: params[:url], status: :pending)
    # TODO: Run ParseRecipeJob
    ParseRecipeJob.set(wait: 1.second).perform_later(recipe.id)
    redirect_to recipe
  end
end
