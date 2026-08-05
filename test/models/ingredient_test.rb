require "test_helper"

class IngredientTest < ActiveSupport::TestCase
  test "display_name prefers the split name over content" do
    ingredient = Ingredient.new(content: "2 dl mjölk", name: "mjölk")

    assert_equal "mjölk", ingredient.display_name
  end

  test "display_name falls back to content when unsplit" do
    ingredient = Ingredient.new(content: "2 dl mjölk")

    assert_equal "2 dl mjölk", ingredient.display_name
  end

  test "formatted_amount combines quantity and unit" do
    ingredient = Ingredient.new(quantity: "2", unit: "dl")

    assert_equal "2 dl", ingredient.formatted_amount
  end

  test "formatted_amount handles a missing unit" do
    ingredient = Ingredient.new(quantity: "3")

    assert_equal "3", ingredient.formatted_amount
  end

  test "formatted_amount is nil when there's no quantity or unit" do
    ingredient = Ingredient.new(content: "Salt & Peppar", name: "Salt & Peppar")

    assert_nil ingredient.formatted_amount
  end
end
