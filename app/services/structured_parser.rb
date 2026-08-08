class StructuredParser < Parser
  attr_reader :ingredients, :steps

  def initialize(html)
    @html = html
    @ingredients = nil
    @steps = nil
  end

  def call
    node = find_recipe_node
    return bail(:no_recipe_node) unless node

    @ingredients = extract_ingredients(node["recipeIngredient"])
    @steps = extract_instructions(node["recipeInstructions"])

    return bail(:missing_content) if @ingredients.blank? || @steps.blank?
    return bail(:steps_look_unseparated) if steps_look_unseparated?
    return bail(:ingredients_missing_amounts) if ingredients_missing_amounts?

    ratings = extract_ratings(node["aggregateRating"])

    normalize(
      title: node["name"],
      description: node["description"],
      image_url: extract_image_url(node["image"]),
      prep_time: node["prepTime"],
      cook_time: node["cookTime"],
      total_time: node["totalTime"],
      servings: extract_servings(node["recipeYield"]),
      source_domain: extract_source_domain(node["url"] || extract_image_url(node["image"])),
      external_rating: ratings[0],
      external_rating_count: ratings[1]
    )
  rescue StandardError => e
    bail(:exception, e)
  end

  private

  # Every early-exit from #call funnels through here so a fallback to LlmParser
  # always has a logged reason instead of a silent nil — worth grepping for
  # ("StructuredParser bailed:") when a site keeps ending up on the LLM path.
  def bail(reason, error = nil)
    detail = error ? " (#{error.class}: #{error.message})" : ""
    Rails.logger.info("StructuredParser bailed: #{reason}#{detail}")
    nil
  end

  def extract_ratings(aggregate_rating)
    return [ nil, nil ] unless aggregate_rating

    rating_value = aggregate_rating["ratingValue"]
    rating_count = (aggregate_rating["ratingCount"] || aggregate_rating["reviewCount"])
    return [ nil, nil ] unless rating_value

    best = (aggregate_rating["bestRating"] || 5).to_f
    worst = (aggregate_rating["worstRating"] || 1).to_f
    return [ nil, nil ] if best == worst
    normalized = 1 + (rating_value.to_f - worst) / (best - worst) * 4

    [ normalized, rating_count.to_i ]
  end

  # Some sites hand back one giant string with no real step boundaries (steps
  # joined with plain spaces instead of separate array entries) — a single
  # "step" with several sentence breaks is a sign of that, not a genuinely
  # short one-step recipe. Bail so LlmParser splits it properly instead.
  def steps_look_unseparated?
    return false unless @steps.size == 1

    step = @steps.first.to_s
    step.scan(/\.\s/).size >= 3 || step.length > 600
  end

  def ingredients_missing_amounts?
    @ingredients.none? { |ingredient| ingredient.match?(/[\d½⅓⅔¼¾⅕⅙⅛]/) }
  end

  def extract_ingredients(ingredients)
    Array(ingredients).map { |ingredient| decode_entities(ingredient.to_s) }
  end

  def extract_source_domain(url)
    URI.parse(url).host
  end

  def extract_image_url(image)
    case image
    when String then image
    when Hash then image["url"]
    when Array then extract_image_url(image.first)
    end
  end

  def extract_servings(recipe_yield)
    Array(recipe_yield).first
  end

  def find_recipe_node
    doc = Nokogiri::HTML(@html)

    doc.css('script[type="application/ld+json"]').each do |script|
      json = safe_parse(script.text)
      next unless json

      recipe = flatten(json).find { |node| recipe_type?(node) }
      return recipe if recipe
    end

    nil
  end

  def flatten(json)
    case json
    when Array then json.flat_map { |item| flatten(item) }
    when Hash then json["@graph"] ? flatten(json["@graph"]) : [ json ]
    else []
    end
  end

  def recipe_type?(node)
    Array(node["@type"]).include?("Recipe")
  end

  def safe_parse(text)
    JSON.parse(text)
  rescue JSON::ParserError
    nil
  end

  def extract_instructions(instructions)
    Array(instructions).flat_map { |item| flatten_instruction(item) }.compact_blank
  end

  # recipeInstructions is sometimes a flat array of strings/HowToSteps, but some
  # sites group steps under HowToSection objects instead ({ "@type" => "HowToSection",
  # "itemListElement" => [HowToStep, ...] }) — recurse into those to get a flat list.
  def flatten_instruction(item)
    return decode_entities(item.to_s) if item.is_a?(String)
    return [] unless item.is_a?(Hash)

    if Array(item["@type"]).include?("HowToSection")
      Array(item["itemListElement"]).flat_map { |sub_item| flatten_instruction(sub_item) }
    else
      decode_entities(item["text"])
    end
  end
end
