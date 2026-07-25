class SavedRecipesController < ApplicationController
  def create
    recipe = Recipe.find(params[:recipe_id])
    collection = find_or_create_collection

    if collection.nil?
      return redirect_to recipe, alert: "Ange ett namn för den nya samlingen."
    end

    saved_recipe = Current.user.saved_recipes.new(collection: collection, recipe: recipe)

    if saved_recipe.save
      recipe.publish!
      redirect_to recipe
    else
      redirect_to recipe, alert: "Det gick inte att spara receptet i den samlingen."
    end
  end

  private

  def find_or_create_collection
    if params[:collection_id] == "new"
      name = params[:new_collection_name].to_s.strip
      return nil if name.blank?

      Current.user.collections.create!(name: name)
    else
      Current.user.collections.find_by(id: params[:collection_id])
    end
  end
end
