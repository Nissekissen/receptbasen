require "test_helper"

class IngredientExtractorTest < ActiveSupport::TestCase
  test "splits ingredients into quantity, unit, name, and quantity_value" do
    response = {
      ingredients: [
        { quantity: "2", unit: "dl", name: "mjölk", quantity_value: 2 },
        { quantity: "3", unit: nil, name: "ägg", quantity_value: 3 }
      ]
    }.to_json
    stub_anthropic_messages(response)

    result = IngredientExtractor.new(ingredients: [ "2 dl mjölk", "3 ägg" ]).call

    assert_equal [
      { quantity: "2", unit: "dl", name: "mjölk", quantity_value: 2 },
      { quantity: "3", unit: nil, name: "ägg", quantity_value: 3 }
    ], result
  end

  test "converts a fraction quantity into a decimal quantity_value" do
    response = {
      ingredients: [
        { quantity: "1/2", unit: "dl", name: "socker", quantity_value: 0.5 }
      ]
    }.to_json
    stub_anthropic_messages(response)

    result = IngredientExtractor.new(ingredients: [ "1/2 dl socker" ]).call

    assert_equal [ { quantity: "1/2", unit: "dl", name: "socker", quantity_value: 0.5 } ], result
  end

  test "returns nil quantity, unit, and quantity_value for ingredients with no real amount" do
    response = {
      ingredients: [
        { quantity: nil, unit: nil, name: "Salt & Peppar", quantity_value: nil }
      ]
    }.to_json
    stub_anthropic_messages(response)

    result = IngredientExtractor.new(ingredients: [ "Salt & Peppar" ]).call

    assert_equal [ { quantity: nil, unit: nil, name: "Salt & Peppar", quantity_value: nil } ], result
  end

  test "fails when the response doesn't have one entry per ingredient" do
    response = { ingredients: [ { quantity: "2", unit: "dl", name: "mjölk" } ] }.to_json
    stub_anthropic_messages(response)

    extractor = IngredientExtractor.new(ingredients: [ "2 dl mjölk", "3 ägg" ])
    result = extractor.call

    assert_nil result
    assert_equal "Mismatched ingredient count", extractor.error
  end
end
