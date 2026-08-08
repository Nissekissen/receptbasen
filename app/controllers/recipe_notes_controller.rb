class RecipeNotesController < ApplicationController
  before_action :set_recipe

  def create
    raise ActiveRecord::RecordNotFound unless @recipe.visible_to?(Current.user)

    @note = PersonalRecipeNote.find_or_initialize_by(user: Current.user, recipe: @recipe)

    hash = {}
    hash[:content] = params[:content] if params[:content] != nil
    hash[:rating] = params[:rating].to_i if params[:rating] != nil

    @note.update(hash)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @recipe }
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end
end
