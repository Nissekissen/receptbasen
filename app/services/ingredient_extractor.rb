class IngredientExtractor
  RESPONSE_SCHEMA = {
    type: "object",
    properties: {
      ingredients: {
        type: "array",
        items: {
          type: "object",
          properties: {
            quantity: { anyOf: [ { type: "string" }, { type: "null" } ] },
            unit: { anyOf: [ { type: "string" }, { type: "null" } ] },
            name: { type: "string" }
          },
          required: [ "quantity", "unit", "name" ],
          additionalProperties: false
        }
      }
    },
    required: [ "ingredients" ],
    additionalProperties: false
  }

  attr_reader :error

  def initialize(ingredients:)
    @ingredients = ingredients
    @error = nil
  end

  def call
    response = client.messages.create(
      model: :"claude-haiku-4-5",
      max_tokens: 2048,
      output_config: { format: { type: "json_schema", schema: RESPONSE_SCHEMA } },
      messages: [ { role: "user", content: prompt } ]
    )

    parsed = JSON.parse(response.content.find { |b| b.type == :text }.text)["ingredients"]

    if parsed.size != @ingredients.size
      @error = "Mismatched ingredient count"
      return nil
    end

    parsed.map { |h| { quantity: h["quantity"], unit: h["unit"], name: h["name"] } }
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
      Split each ingredient line below into quantity, unit, and name. Return exactly
      #{@ingredients.size} items, one per line, in the same order given.

      If a line has no real amount (e.g. "Salt & Peppar", "Olja till stekning"), set
      quantity and unit to null and put the full descriptive text in name — never invent
      a quantity that isn't there.

      Ingredients:
      #{@ingredients.each_with_index.map { |content, index| "#{index + 1}. #{content}" }.join("\n")}
    PROMPT
  end
end
