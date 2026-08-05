class ParseRecipeJob < ApplicationJob
  queue_as :default

  class FetchError < StandardError; end

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)

    html = fetch_page(recipe.source_url)
    broadcast_step(recipe, :fetch, :done)

    broadcast_step(recipe, :parse, :active)

    ingredients = nil
    steps = nil

    structured_parser = StructuredParser.new(html)
    result = structured_parser.call
    if result
      ingredients = structured_parser.ingredients
      steps = structured_parser.steps
    end

    if result.nil?
      # Use LLM parser instead
      broadcast_step(recipe, :parse, :failed)
      broadcast_step(recipe, :parse_ai, :active)

      llm_parser = LlmParser.new(html)
      result = llm_parser.call

      if result.nil?
        Rails.logger.info "ParseRecipeJob: LlmParser failed for recipe #{recipe.id}: #{llm_parser.error}"
        broadcast_step(recipe, :parse_ai, :failed)
        broadcast_failed(recipe, user_facing_error(llm_parser.error))
        return
      end

      ingredients = llm_parser.ingredients
      steps = llm_parser.steps

      broadcast_step(recipe, :parse_ai, :done)
    else
      broadcast_step(recipe, :parse, :done)
    end

    recipe.update!(result)
    recipe.update!(status: :done)

    recipe.ingredients.create!(ingredients.map { |content| { content: content } })
    recipe.steps.create!(steps.each_with_index.map { |content, index| { content: content, position: index } })

    split_ingredients(recipe)

    broadcast_step(recipe, :tags, :active)

    tag_extractor = TagExtractor.new(title: recipe.title, description: recipe.description, ingredients: recipe.ingredients.map(&:content))
    result = tag_extractor.call

    if result.nil?
      broadcast_failed(recipe, nil)
      return
    end

    recipe.tags = result.map { |tag| Tag.find_or_create_by!(name: tag[:name]) { |t| t.category = tag[:category] } }

    broadcast_step(recipe, :tags, :done)

    sleep 0.5
    broadcast_ready(recipe)
  rescue Faraday::Error, FetchError => e
    Rails.logger.error "ParseRecipeJob fetch error for recipe #{recipe.id}: #{e.class} - #{e.message}"
    broadcast_step(recipe, :fetch, :failed)
    broadcast_failed(recipe, "Det gick inte att hämta sidan. Kontrollera länken och försök igen.")
  rescue StandardError => e
    Rails.logger.error "ParseRecipeJob error for recipe #{recipe_id}: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n") if e.backtrace
    broadcast_failed(recipe, "Något gick fel. Försök igen senare.") if recipe
  end

  private

  def broadcast_step(recipe, step, state)
    Turbo::StreamsChannel.broadcast_replace_to(
      "recipe_#{recipe.id}_loading",
      target: "step-#{step}",
      partial: "recipes/loading_step",
      locals: { step: step, state: state }
    )
  end

  # A failure here is non-blocking, unlike TagExtractor below — splitting is a display
  # enhancement, not core to whether the recipe was saved successfully, so a failed or
  # mismatched extraction just leaves quantity/unit/name nil rather than failing the recipe.
  def split_ingredients(recipe)
    ingredient_extractor = IngredientExtractor.new(ingredients: recipe.ingredients.map(&:content))
    split = ingredient_extractor.call

    if split
      recipe.ingredients.order(:id).zip(split).each { |ingredient, fields| ingredient.update!(fields) }
    else
      Rails.logger.info "ParseRecipeJob: IngredientExtractor failed for recipe #{recipe.id}: #{ingredient_extractor.error}"
    end
  end

  def user_facing_error(error)
    case error
    when "Not a recipe"
      "Länken verkar inte leda till ett recept. Prova en annan länk."
    when "No ingredients or steps"
      "Vi kunde inte hitta ingredienser eller steg på sidan. Prova en annan länk."
    end
  end

  def broadcast_failed(recipe, error)
    recipe.update!(status: :failed)

    Turbo::StreamsChannel.broadcast_update_to(
      "recipe_#{recipe.id}_loading",
      target: "recipe_card",
      partial: "recipes/steps/failed",
      locals: { recipe: recipe, error: error }
    )
  end

  def broadcast_ready(recipe)
    Turbo::StreamsChannel.broadcast_update_to(
      "recipe_#{recipe.id}_loading",
      target: "recipe_card",
      partial: "recipes/steps/ready",
      locals: { recipe: recipe }
    )
  end

  def fetch_page(url)
    connection = Faraday.new do |f|
      f.use Faraday::FollowRedirects::Middleware
      f.options.timeout = 10
      f.headers["User-Agent"] = "Mozilla/5.0 (compatible; ReceptbasenBot/1.0)"
    end

    response = connection.get(url)
    raise FetchError, "Failed to fetch page: #{response.status}" unless response.success?

    response.body
  end
end
