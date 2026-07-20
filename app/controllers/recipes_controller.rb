class RecipesController < ApplicationController
  def show
    @recipe = Recipe.find(params[:id])
  end

  def create
    recipe = Recipe.create!(source_url: params[:url], status: :pending)
    # TODO: Run ParseRecipeJob
    redirect_to recipe
  end
end
