namespace :ingredients do
  desc "Split any unsplit ingredient content into quantity/unit/name"
  task split: :environment do
    recipe_ids = Ingredient.where(name: nil).distinct.pluck(:recipe_id)

    recipe_ids.each do |recipe_id|
      recipe = Recipe.find(recipe_id)
      extractor = IngredientExtractor.new(ingredients: recipe.ingredients.map(&:content))
      split = extractor.call

      if split
        recipe.ingredients.order(:id).zip(split).each { |ingredient, fields| ingredient.update!(fields) }
        puts "Recipe #{recipe_id}: split #{split.size} ingredients"
      else
        puts "Recipe #{recipe_id}: FAILED (#{extractor.error})"
      end
    rescue => e
      puts "Recipe #{recipe_id}: FAILED (#{e.class}: #{e.message})"
    end
  end
end
