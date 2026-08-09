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
            name: { type: "string" },
            quantity_value: { anyOf: [ { type: "number" }, { type: "null" } ] }
          },
          required: [ "quantity", "unit", "name", "quantity_value" ],
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

    parsed.map { |h| { quantity: h["quantity"], unit: h["unit"], name: h["name"], quantity_value: h["quantity_value"] } }
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

      Also return quantity_value: the same amount as a plain number, for scaling the
      recipe up or down later. Convert fractions and mixed numbers to decimals (e.g.
      "1/2" → 0.5, "1 1/2" → 1.5). For a range (e.g. "2-3 dl"), use the low end (2).
      If quantity is null, quantity_value must be null too — never invent a number for
      a line that has no real amount.

      Ingredients:
      #{@ingredients.each_with_index.map { |content, index| "#{index + 1}. #{content}" }.join("\n")}
    PROMPT
  end
end
