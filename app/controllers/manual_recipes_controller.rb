class ManualRecipesController < ApplicationController
  def new
    @recipe = Recipe.new
  end

  def create
    if params[:recipe][:title].blank?
      return redirect_to new_manual_recipe_path, alert: "Titel krävs."
    end

    ingredients = Array(params[:ingredients]).reject(&:blank?)
    steps = Array(params[:steps]).reject(&:blank?)

    if ingredients.empty? || steps.empty?
      return redirect_to new_manual_recipe_path, alert: "Minst en ingredients och ett steg."
    end

    recipe = Recipe.new(recipe_params)
    recipe.owner = Current.user
    recipe.status = :done

    if params[:total_time_minutes].present?
      # discard cook and prep time
      recipe.total_time = minutes_to_duration(params[:total_time_minutes])
    else
      recipe.prep_time = minutes_to_duration(params[:prep_time_minutes])
      recipe.cook_time = minutes_to_duration[params[:cook_time_minutes]]
    end

    recipe.save!

    recipe.ingredients.create!(ingredients.map { |content| { content: content } })
    recipe.steps.create!(steps.each_with_index.map { |content, index| { content: content, position: index } })

    redirect_to recipe
  end

  private

  def recipe_params
    params.expect(recipe: [:title, :description, :image_url, :servings])
  end

  def minutes_to_duration(minutes)
    return nil if minutes.blank?
    "PT#{minutes.to_i}M"
  end
end
