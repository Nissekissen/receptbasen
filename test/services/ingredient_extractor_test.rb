require "test_helper"

class IngredientExtractorTest < ActiveSupport::TestCase
  test "splits ingredients into quantity, unit, and name" do
    response = {
      ingredients: [
        { quantity: "2", unit: "dl", name: "mjölk" },
        { quantity: "3", unit: nil, name: "ägg" }
      ]
    }.to_json
    stub_anthropic_messages(response)

    result = IngredientExtractor.new(ingredients: [ "2 dl mjölk", "3 ägg" ]).call

    assert_equal [
      { quantity: "2", unit: "dl", name: "mjölk" },
      { quantity: "3", unit: nil, name: "ägg" }
    ], result
  end

  test "returns nil quantity and unit for ingredients with no real amount" do
    response = {
      ingredients: [
        { quantity: nil, unit: nil, name: "Salt & Peppar" }
      ]
    }.to_json
    stub_anthropic_messages(response)

    result = IngredientExtractor.new(ingredients: [ "Salt & Peppar" ]).call

    assert_equal [ { quantity: nil, unit: nil, name: "Salt & Peppar" } ], result
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
