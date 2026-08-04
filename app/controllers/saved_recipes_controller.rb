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
      params[:silent] == "true" ? head(:no_content) : redirect_to(recipe)
    else
      redirect_to recipe, alert: "Det gick inte att spara receptet i den samlingen."
    end
  end

  def destroy
    Current.user.saved_recipes.find(params[:id]).destroy
    head :no_content
  end

  def toggle
    recipe = Recipe.find(params[:recipe_id])
    collection = Collection.find(params[:collection_id])
    raise ActiveRecord::RecordNotFound unless collection.accessible_to?(Current.user)

    saved_recipe = SavedRecipe.find_by(recipe: recipe, collection: collection)

    if saved_recipe
      saved_recipe.destroy
    else
      Current.user.saved_recipes.create!(recipe: recipe, collection: collection)
      recipe.publish!
    end

    head :no_content
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
