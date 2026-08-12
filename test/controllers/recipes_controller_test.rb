require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  TAG_RESPONSE = {
    maltidstyp: [ "huvudrätt" ],
    kok: [ "svenskt" ],
    kost: [],
    svarighetsgrad: "medel"
  }.to_json

  test "shows a published recipe" do
    get recipe_url(recipes(:pannkakor))
    assert_response :success
  end

  test "redirects to login for viewing an unpublished recipe" do
    get recipe_url(recipes(:parsed_unpublished_recipe))
    assert_redirected_to new_session_path
  end

  test "shows a manual recipe to its owner" do
    sign_in_as(users(:one))

    get recipe_url(recipes(:kottbullar))

    assert_response :success
  end

  test "404s a manual recipe for a signed-in non-owner" do
    sign_in_as(users(:two))

    get recipe_url(recipes(:kottbullar))

    assert_response :not_found
  end

  test "404s a manual recipe for an anonymous visitor" do
    get recipe_url(recipes(:kottbullar))

    assert_response :not_found
  end

  test "shows a manual recipe to a fellow group member once it's saved in a group collection" do
    sign_in_as(users(:one))

    get recipe_url(recipes(:manual_recipe_in_group))

    assert_response :success
  end

  test "404s a manual recipe saved in a group collection for a user outside that group" do
    sign_in_as(users(:three))

    get recipe_url(recipes(:manual_recipe_in_group))

    assert_response :not_found
  end

  test "redirects to the existing recipe instead of creating a duplicate" do
    assert_no_difference "Recipe.count" do
      post recipes_url, params: { url: recipes(:pannkakor).source_url }
    end

    assert_redirected_to recipes(:pannkakor)
  end

  test "creates a new pending recipe and enqueues a parse job" do
    assert_enqueued_with(job: ParseRecipeJob) do
      assert_difference "Recipe.count", 1 do
        post recipes_url, params: { url: "https://newsite.example.com/recept/ny" }
      end
    end

    recipe = Recipe.last
    assert_predicate recipe, :pending?
    assert_redirected_to recipe
  end

  test "destroys an unpublished scraped recipe" do
    assert_difference "Recipe.count", -1 do
      delete recipe_url(recipes(:pending_recipe))
    end

    assert_redirected_to root_path
  end

  test "prevents destroying a published scraped recipe" do
    assert_no_difference "Recipe.count" do
      delete recipe_url(recipes(:pannkakor))
    end

    assert_response :not_found
  end

  test "allows the owner to destroy their manual recipe" do
    sign_in_as(users(:one))

    assert_difference "Recipe.count", -1 do
      delete recipe_url(recipes(:kottbullar))
    end

    assert_redirected_to root_path
  end

  test "prevents a non-owner from destroying a manual recipe" do
    sign_in_as(users(:two))

    assert_no_difference "Recipe.count" do
      delete recipe_url(recipes(:kottbullar))
    end

    assert_response :not_found
  end

  test "requires authentication to list saved recipes" do
    get recipes_url
    assert_redirected_to new_session_path
  end

  test "lists only the current user's saved recipes" do
    sign_in_as(users(:one))

    get recipes_url

    assert_response :success
    assert_select ".recipe-preview--title", text: "Pannkakor"
    assert_select ".recipe-preview--title", text: "Mormors köttbullar", count: 0
  end

  test "the collection filter does not include group collections, even ones the user created" do
    sign_in_as(users(:one))

    get recipes_url

    assert_response :success
    assert_select "option", text: "Grillrecept", count: 0
  end

  test "the post-parse collection picker does not include group collections" do
    sign_in_as(users(:one))

    get recipe_url(recipes(:parsed_unpublished_recipe))

    assert_response :success
    assert_select "option", text: "Grillrecept", count: 0
  end

  test "requires authentication to extract tags" do
    post extract_tags_recipe_url(recipes(:pannkakor))
    assert_redirected_to new_session_path
  end

  test "extracts and assigns tags for a scraped recipe via turbo_stream" do
    sign_in_as(users(:one))
    stub_anthropic_messages(TAG_RESPONSE)

    post extract_tags_recipe_url(recipes(:pannkakor)), as: :turbo_stream

    assert_response :success
    assert_equal [ "huvudrätt", "svenskt", "medel" ], recipes(:pannkakor).reload.tags.map(&:name)
  end

  test "redirects after extracting tags for an html request" do
    sign_in_as(users(:one))
    stub_anthropic_messages(TAG_RESPONSE)

    post extract_tags_recipe_url(recipes(:pannkakor))

    assert_redirected_to recipes(:pannkakor)
  end

  test "allows the owner to extract tags on their manual recipe" do
    sign_in_as(users(:one))
    stub_anthropic_messages(TAG_RESPONSE)

    post extract_tags_recipe_url(recipes(:kottbullar))

    assert_redirected_to recipes(:kottbullar)
    assert_equal [ "huvudrätt", "svenskt", "medel" ], recipes(:kottbullar).reload.tags.map(&:name)
  end

  test "404s when a non-owner tries to extract tags on a manual recipe" do
    sign_in_as(users(:two))

    post extract_tags_recipe_url(recipes(:kottbullar))

    assert_response :not_found
  end

  test "requires authentication to add to the shopping list" do
    post add_to_shopping_list_recipe_url(recipes(:pannkakor))

    assert_redirected_to new_session_path
  end

  test "adds all of a recipe's ingredients to the shopping list" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "2 dl mjölk", quantity: "2", unit: "dl", name: "mjölk")
    recipe.ingredients.create!(content: "3 ägg")

    assert_difference "ShoppingListItem.count", 2 do
      post add_to_shopping_list_recipe_url(recipe)
    end

    items = users(:one).shopping_list_items.where(recipe: recipe).order(:id)
    assert_equal [ "2 dl mjölk", "3 ägg" ], items.pluck(:content)
    assert_equal [ "2", nil ], items.pluck(:quantity)
    assert_equal [ "dl", nil ], items.pluck(:unit)
    assert_equal [ "mjölk", nil ], items.pluck(:name)
    assert_redirected_to recipe
  end

  test "scales ingredient quantities in the shopping list by the scale param" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "2 dl mjölk", quantity: "2", unit: "dl", name: "mjölk", quantity_value: 2.0)
    recipe.ingredients.create!(content: "Salt & peppar")

    post add_to_shopping_list_recipe_url(recipe), params: { scale: 1.5 }

    items = users(:one).shopping_list_items.where(recipe: recipe).order(:id)
    assert_equal [ "3", nil ], items.pluck(:quantity)
    assert_equal [ "dl", nil ], items.pluck(:unit)
    assert_equal "Salt & peppar", items.second.content
  end

  test "drops trailing zeros when scaling produces a whole number" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "4 dl mjöl", quantity: "4", unit: "dl", name: "mjöl", quantity_value: 4.0)

    post add_to_shopping_list_recipe_url(recipe), params: { scale: 0.5 }

    item = users(:one).shopping_list_items.find_by(recipe: recipe)
    assert_equal "2", item.quantity
  end

  test "rounds scaled quantities to two decimals" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "1 dl socker", quantity: "1", unit: "dl", name: "socker", quantity_value: 1.0)

    post add_to_shopping_list_recipe_url(recipe), params: { scale: (1.0 / 3).to_s }

    item = users(:one).shopping_list_items.find_by(recipe: recipe)
    assert_equal "0.33", item.quantity
  end

  test "does not scale ingredients with no quantity_value" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "2 dl mjölk", quantity: "2", unit: "dl", name: "mjölk")

    post add_to_shopping_list_recipe_url(recipe), params: { scale: 2 }

    item = users(:one).shopping_list_items.find_by(recipe: recipe)
    assert_equal "2", item.quantity
  end

  test "defaults to no scaling when the scale param is absent" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "2 dl mjölk", quantity: "2", unit: "dl", name: "mjölk", quantity_value: 2.0)

    post add_to_shopping_list_recipe_url(recipe)

    item = users(:one).shopping_list_items.find_by(recipe: recipe)
    assert_equal "2", item.quantity
  end

  test "responds with a turbo stream when adding to the shopping list" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.ingredients.create!(content: "Mjöl")

    post add_to_shopping_list_recipe_url(recipe), as: :turbo_stream

    assert_response :success
  end

  test "owner can add their manual recipe's ingredients to the shopping list" do
    sign_in_as(users(:one))
    recipe = recipes(:kottbullar)
    recipe.ingredients.create!(content: "500 g köttfärs")

    assert_difference "ShoppingListItem.count", 1 do
      post add_to_shopping_list_recipe_url(recipe)
    end
  end

  test "404s adding a private manual recipe's ingredients for a non-owner" do
    sign_in_as(users(:two))
    recipe = recipes(:kottbullar)
    recipe.ingredients.create!(content: "500 g köttfärs")

    assert_no_difference "ShoppingListItem.count" do
      post add_to_shopping_list_recipe_url(recipe)
    end

    assert_response :not_found
  end

  test "requires authentication for cook mode" do
    get cook_recipe_url(recipes(:pannkakor))

    assert_redirected_to new_session_path
  end

  test "renders cook mode for a visible recipe" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.steps.create!(content: "Vispa ihop mjöl och mjölk.", position: 0)
    recipe.steps.create!(content: "Stek i 5 minuter per sida.", position: 1)
    recipe.ingredients.create!(content: "2 dl mjöl", quantity: "2", unit: "dl", name: "mjöl")

    get cook_recipe_url(recipe)

    assert_response :success
  end

  test "renders cook mode for a recipe with a single step" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)
    recipe.steps.create!(content: "Stek pannkakorna.", position: 0)

    get cook_recipe_url(recipe)

    assert_response :success
  end

  test "owner can enter cook mode for their manual recipe" do
    sign_in_as(users(:one))
    recipe = recipes(:kottbullar)
    recipe.steps.create!(content: "Blanda köttfärsen.", position: 0)

    get cook_recipe_url(recipe)

    assert_response :success
  end

  test "404s cook mode for a private manual recipe the signed-in user can't see" do
    sign_in_as(users(:two))
    recipe = recipes(:kottbullar)
    recipe.steps.create!(content: "Blanda köttfärsen.", position: 0)

    get cook_recipe_url(recipe)

    assert_response :not_found
  end

  test "requires authentication to log a cook" do
    post log_cook_recipe_url(recipes(:pannkakor))

    assert_redirected_to new_session_path
  end

  test "logs a cook and redirects back to the recipe" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)

    assert_difference "recipe.cook_logs.count", 1 do
      post log_cook_recipe_url(recipe)
    end

    assert_equal users(:one), recipe.cook_logs.last.user
    assert_redirected_to recipe
  end

  test "logging the same recipe twice creates two cook_logs rows" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)

    assert_difference "recipe.cook_logs.count", 2 do
      post log_cook_recipe_url(recipe)
      post log_cook_recipe_url(recipe)
    end
  end

  test "logs a cook and updates the count badge via turbo_stream" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)

    post log_cook_recipe_url(recipe), as: :turbo_stream

    assert_response :success
    assert_match "Lagad 3 ggr", @response.body
  end

  test "404s logging a cook for a private manual recipe the signed-in user can't see" do
    sign_in_as(users(:two))

    assert_no_difference "CookLog.count" do
      post log_cook_recipe_url(recipes(:kottbullar))
    end

    assert_response :not_found
  end
end
