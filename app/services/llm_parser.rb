class LlmParser < Parser
  RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      is_recipe: { type: "boolean" },
      title: { type: "string" },
      description: { type: "string" },
      image_url: { type: "string" },
      prep_time: { type: "string" },
      cook_time: { type: "string" },
      total_time: { type: "string" },
      servings: { type: "string" },
      source_domain: { type: "string" },
      ingredients: { type: "array", items: { type: "string" } },
      steps: { type: "array", items: { type: "string" } }
    },
    required: [ "is_recipe" ],
    additionalProperties: false
  }

  attr_reader :error, :ingredients, :steps

  def initialize(html)
    @html = html
    @error = nil
    @ingredients = nil
    @steps = nil
  end

  def call
    response = client.messages.create(
      model: :"claude-haiku-4-5",
      max_tokens: 2048,
      output_config: { format: { type: "json_schema", schema: RESPONSE_SCHEMA } },
      messages: [ { role: "user", content: prompt } ]
    )

    result = JSON.parse(response.content.find { |b| b.type == :text }.text)

    unless result["is_recipe"]
      @error = "Not a recipe"
      return nil
    end

    if result["ingredients"].blank? || result["steps"].blank?
      @error = "No ingredients or steps"
      return nil
    end

    @ingredients = result["ingredients"]
    @steps = result["steps"]

    normalize(result)
  end

  private

  def client
    @client ||= Anthropic::Client.new
  end

  def shrink_html
    # Remove script tags, but keep application/ld+json ones — that's often the
    # cleanest source of the actual recipe data (title/ingredients/steps), and
    # stripping it blindly along with real JS left the LLM working from just
    # the visible page markup, which some sites render.
    @html = @html.gsub(%r{<script(?![^>]*application/ld\+json)[^>]*>.*?</script>}mi, "")
    @html = @html.gsub(/<style[^>]*>.*?<\/style>/m, "")
    @html
  end

  def prompt
    <<~PROMPT
    Extract the recipe from this page if one exists. If this page does not contain an actual recipe with ingredients and steps, set is_recipe to false and don't fabricate content.

    Provide the ingredients and steps exactly as they appear in the HTML, except strip any
    leading step numbering (e.g. "1.", "2)", "Steg 3:") from each step — the app numbers
    steps itself, so a leading number would end up shown twice.
    Provide prep time and cook time in the ISO 8601 format. If the page only gives a single
    total time instead of separate prep/cook times, put it in total_time and leave prep_time
    and cook_time blank.

    #{shrink_html}
    PROMPT
  end
end
