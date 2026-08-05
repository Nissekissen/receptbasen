class StructuredParser < Parser
  attr_reader :ingredients, :steps

  def initialize(html)
    @html = html
    @ingredients = nil
    @steps = nil
  end

  def call
    node = find_recipe_node
    return nil unless node

    @ingredients = extract_ingredients(node["recipeIngredient"])
    @steps = extract_instructions(node["recipeInstructions"])

    return nil if @ingredients.blank? || @steps.blank?

    normalize(
      title: node["name"],
      description: node["description"],
      image_url: extract_image_url(node["image"]),
      prep_time: node["prepTime"],
      cook_time: node["cookTime"],
      total_time: node["totalTime"],
      servings: extract_servings(node["recipeYield"]),
      source_domain: extract_source_domain(node["url"] || extract_image_url(node["image"]))
    )
  rescue StandardError
    nil
  end

  private

  def extract_ingredients(ingredients)
    Array(ingredients).map(&:to_s)
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
    when Hash then json["@graph"] ? flatten(json["@graph"]) : [json]
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
    return item.to_s if item.is_a?(String)
    return [] unless item.is_a?(Hash)

    if Array(item["@type"]).include?("HowToSection")
      Array(item["itemListElement"]).flat_map { |sub_item| flatten_instruction(sub_item) }
    else
      item["text"]
    end
  end
end
