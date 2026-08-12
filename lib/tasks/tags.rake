namespace :tags do
  desc "Attach the deterministic snabbt/långkok tag to recipes that have parseable time data but no tid tag yet"
  task backfill_time: :environment do
    recipes = Recipe.where.not(id: Tagging.joins(:tag).where(tags: { category: :tid }).select(:recipe_id))

    recipes.find_each do |recipe|
      tag = recipe.time_tag
      next unless tag

      recipe.tags << tag unless recipe.tags.include?(tag)
      puts "Recipe #{recipe.id}: tagged #{tag.name}"
    rescue => e
      puts "Recipe #{recipe.id}: FAILED (#{e.class}: #{e.message})"
    end
  end
end
