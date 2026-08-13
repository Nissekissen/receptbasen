namespace :ingredients do
  desc "Split any unsplit ingredient content into quantity/unit/name"
  task split: :environment do
    recipe_ids = Ingredient.where(quantity_value: nil).distinct.pluck(:recipe_id)

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

  desc "Re-fetch and re-parse ingredients for scraped recipes whose content never captured an amount (recipes scraped before StructuredParser#ingredients_missing_amounts? started catching this). Set DRY_RUN=true to only list affected recipes."
  task refetch_missing_amounts: :environment do
    amount_pattern = /[\d½⅓⅔¼¾⅕⅙⅛]/

    affected = Recipe.done.where(owner_id: nil).where.not(source_url: nil).includes(:ingredients).select do |recipe|
      recipe.ingredients.any? && recipe.ingredients.none? { |ingredient| ingredient.content.match?(amount_pattern) }
    end

    puts "Found #{affected.size} recipe(s) with no ingredient amounts:"
    affected.each { |recipe| puts "  ##{recipe.id} #{recipe.title} (#{recipe.source_domain})" }

    if ENV["DRY_RUN"].present?
      puts "DRY_RUN set, stopping here."
      next
    end

    affected.each_with_index do |recipe, index|
      sleep 3 if index.positive?

      connection = Faraday.new do |f|
        f.use Faraday::FollowRedirects::Middleware
        f.options.timeout = 10
        f.headers["User-Agent"] = "Mozilla/5.0 (compatible; ReceptbasenBot/1.0)"
      end

      response = connection.get(recipe.source_url)
      raise "Failed to fetch page: #{response.status}" unless response.success?

      llm_parser = LlmParser.new(response.body)
      result = llm_parser.call

      if result.nil?
        puts "Recipe #{recipe.id}: FAILED to re-parse (#{llm_parser.error})"
        next
      end

      if llm_parser.ingredients.none? { |content| content.match?(amount_pattern) }
        puts "Recipe #{recipe.id}: re-fetched, but got no ingredient amounts back this time either (rate-limiting/bot-blocking or a genuinely amount-less page) — leaving existing data as-is, re-run to retry"
        next
      end

      recipe.ingredients.destroy_all
      recipe.ingredients.create!(llm_parser.ingredients.map { |content| { content: content } })

      extractor = IngredientExtractor.new(ingredients: recipe.ingredients.map(&:content))
      split = extractor.call

      if split
        recipe.ingredients.order(:id).zip(split).each { |ingredient, fields| ingredient.update!(fields) }
        puts "Recipe #{recipe.id}: re-fetched and split #{split.size} ingredients"
      else
        puts "Recipe #{recipe.id}: re-fetched ingredients but split FAILED (#{extractor.error})"
      end
    rescue => e
      puts "Recipe #{recipe.id}: FAILED (#{e.class}: #{e.message})"
    end
  end
end
