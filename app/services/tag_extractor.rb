class TagExtractor
  CUISINES = %w[svenskt italienskt franskt mexikanskt asiatiskt indiskt medelhavskök amerikanskt].freeze

  RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      maltidstyp: { type: "string", enum: %w[frukost förrätt huvudrätt efterrätt bakverk tillbehör dryck mellanmål] },
      kok: { anyOf: [{ type: "string", enum: CUISINES }, { type: "null" }] },
      kost: { type: "array", items: { type: "string", enum: %w[vegetariskt veganskt glutenfritt laktosfritt] } },
      svarighetsgrad: { type: "string", enum: %w[lätt medel avancerad] }
    },
    required: ["maltidstyp", "kok", "kost", "svarighetsgrad"],
    additionalProperties: false
  }

  attr_reader :error

  def initialize(title:, ingredients:, description:)
    @title = title
    @ingredients = ingredients
    @description = description
    @error = nil
  end

  def call
    response = client.messages.create(
      model: :"claude-haiku-4-5",
      max_tokens: 1024,
      output_config: { format: { type: "json_schema", schema: RESPONSE_SCHEMA } },
      messages: [{ role: "user", content: prompt }]
    )

    result = JSON.parse(response.content.find { |b| b.type == :text }.text)
    [result["maltidstyp"], result["kok"], *result["kost"], result["svarighetsgrad"]].compact
  rescue => e
    @error = e.message
    nil
  end

  private

  def client
    @client ||= Anthropic::Client.new
  end

  def prompt
    <<~PROMPT
      Categorize this recipe using only the allowed values in the schema. Be conservative — only assign kost (dietary) tags when the ingredients clearly support it, and leave kok (cuisine) null unless the recipe is clearly tied to one.

      Title: #{@title}
      Description: #{@description}
      Ingredients: #{@ingredients.join(", ")}
    PROMPT
  end
end
