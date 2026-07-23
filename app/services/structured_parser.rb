class StructuredParser < Parser
  def initialize(html)
    @html = html
  end

  def call
    node = find_recipe_node
    return nil unless node

    normalize(
      title: node["name"],
      description: node["description"],
      image_url: extract_image_url(node["image"]),
      prep_time: node["prepTime"],
      cook_time: node["cookTime"],
      total_time: node["totalTime"],
      servings: extract_servings(node["recipeYield"]),
      source_domain: extract_source_domain(node["url"] || node["image"]),
      steps: extract_instructions(node["recipeInstructions"])
    )
  end

  private

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
    Array(instructions).map { |step| step.is_a?(Hash) ? step["text"] : step.to_s }
  end
end
