require "test_helper"

class ManualRecipesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post manual_recipe_url, params: { recipe: { title: "Soppa" }, ingredients: [ "Lök" ], steps: [ "Koka" ] }
    assert_redirected_to new_session_path
  end

  test "redirects with an alert when title is blank" do
    sign_in_as(users(:one))

    assert_no_difference "Recipe.count" do
      post manual_recipe_url, params: { recipe: { title: "" }, ingredients: [ "Lök" ], steps: [ "Koka" ] }
    end

    assert_redirected_to new_manual_recipe_path
    assert_equal "Titel krävs.", flash[:alert]
  end

  test "redirects with an alert when ingredients are missing" do
    sign_in_as(users(:one))

    assert_no_difference "Recipe.count" do
      post manual_recipe_url, params: { recipe: { title: "Soppa" }, ingredients: [], steps: [ "Koka" ] }
    end

    assert_redirected_to new_manual_recipe_path
    assert_equal "Minst en ingredients och ett steg.", flash[:alert]
  end

  test "redirects with an alert when steps are missing" do
    sign_in_as(users(:one))

    assert_no_difference "Recipe.count" do
      post manual_recipe_url, params: { recipe: { title: "Soppa" }, ingredients: [ "Lök" ], steps: [] }
    end

    assert_redirected_to new_manual_recipe_path
    assert_equal "Minst en ingredients och ett steg.", flash[:alert]
  end

  test "creates a manual recipe using prep and cook time" do
    sign_in_as(users(:one))
    stub_anthropic_messages({
      ingredients: [
        { quantity: "1", unit: nil, name: "Lök", quantity_value: 1 },
        { quantity: "1", unit: "l", name: "Buljong", quantity_value: 1 }
      ]
    }.to_json)

    assert_difference "Recipe.count", 1 do
      post manual_recipe_url, params: {
        recipe: { title: "Soppa", description: "God soppa", servings: "4" },
        ingredients: [ "Lök", "Buljong" ],
        steps: [ "Hacka löken", "Koka buljongen" ],
        prep_time_minutes: "10",
        cook_time_minutes: "20"
      }
    end

    recipe = Recipe.last
    assert_equal "PT10M", recipe.prep_time
    assert_equal "PT20M", recipe.cook_time
    assert_nil recipe.total_time
    assert_equal users(:one), recipe.owner
    assert_predicate recipe, :done?
    assert_equal [ "Lök", "Buljong" ], recipe.ingredients.map(&:content)
    assert_equal [ "Hacka löken", "Koka buljongen" ], recipe.steps.order(:position).map(&:content)
    assert_redirected_to recipe
  end

  test "creates a manual recipe using total_time, discarding prep and cook time" do
    sign_in_as(users(:one))
    stub_anthropic_messages({ ingredients: [ { quantity: nil, unit: nil, name: "Bröd", quantity_value: nil } ] }.to_json)

    post manual_recipe_url, params: {
      recipe: { title: "Snabbmacka" },
      ingredients: [ "Bröd" ],
      steps: [ "Smörj" ],
      total_time_minutes: "5",
      prep_time_minutes: "10",
      cook_time_minutes: "20"
    }

    recipe = Recipe.last
    assert_equal "PT5M", recipe.total_time
    assert_nil recipe.prep_time
    assert_nil recipe.cook_time
  end

  test "splits manual ingredients into quantity, unit, and quantity_value" do
    sign_in_as(users(:one))
    stub_anthropic_messages({
      ingredients: [
        { quantity: "2", unit: "dl", name: "mjölk", quantity_value: 2 },
        { quantity: "1/2", unit: "dl", name: "socker", quantity_value: 0.5 }
      ]
    }.to_json)

    post manual_recipe_url, params: {
      recipe: { title: "Pannkakor" },
      ingredients: [ "2 dl mjölk", "1/2 dl socker" ],
      steps: [ "Vispa ihop" ]
    }

    recipe = Recipe.last
    assert_equal [ "2", "1/2" ], recipe.ingredients.map(&:quantity)
    assert_equal [ "dl", "dl" ], recipe.ingredients.map(&:unit)
    assert_equal [ 2.0, 0.5 ], recipe.ingredients.map(&:quantity_value)
  end

  test "still creates the recipe when ingredient splitting fails" do
    sign_in_as(users(:one))
    stub_anthropic_messages({ ingredients: [] }.to_json)

    assert_difference "Recipe.count", 1 do
      post manual_recipe_url, params: {
        recipe: { title: "Pannkakor" },
        ingredients: [ "2 dl mjölk", "1/2 dl socker" ],
        steps: [ "Vispa ihop" ]
      }
    end

    recipe = Recipe.last
    assert_equal [ "2 dl mjölk", "1/2 dl socker" ], recipe.ingredients.map(&:content)
    assert recipe.ingredients.all? { |ingredient| ingredient.quantity_value.nil? }
    assert_redirected_to recipe
  end
end
