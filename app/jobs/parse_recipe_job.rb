class ParseRecipeJob < ApplicationJob
  queue_as :default

  def perform(recipe_id)
    recipe = Recipe.find(recipe_id)

    html = fetch_page(recipe.source_url)
    broadcast_step(recipe, :fetch, :done)

    broadcast_step(recipe, :parse, :active)

    # parser = StructuredParser.new(html)
    # result = parser.call

    structured_parser = StructuredParser.new(html)
    result = structured_parser.call

    if result.nil?
      # Use LLM parser instead
      broadcast_step(recipe, :parse, :failed)
      broadcast_step(recipe, :parse_ai, :active)

      llm_parser = LlmParser.new(html)
      result = llm_parser.call

      if result.nil?
        broadcast_step(recipe, :parse_ai, :failed)
        broadcast_error(recipe, llm_parser.error)
        return
      end

      broadcast_step(recipe, :parse_ai, :done)
    else
      broadcast_step(recipe, :parse, :done)
    end

    recipe.update!(result)
    recipe.update!(status: :done)

    sleep 0.5
    broadcast_ready(recipe)
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

  def broadcast_error(recipe, error)
    Turbo::StreamsChannel.broadcast_replace_to(
      "recipe_#{recipe.id}_loading",
      target: "error",
      partial: "recipes/loading_error",
      locals: { error: error }
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
    p "url: #{url}"
    connection = Faraday.new do |f|
      f.use Faraday::FollowRedirects::Middleware
      f.options.timeout = 10
      f.headers["User-Agent"] = "Mozilla/5.0 (compatible; ReceptbasenBot/1.0)"
    end

    response = connection.get(url)
    raise "Failed to fetch page: #{response.status}" unless response.success?

    response.body
  end

end
