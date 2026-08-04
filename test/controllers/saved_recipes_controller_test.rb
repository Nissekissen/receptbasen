require "test_helper"

class SavedRecipesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication to save a recipe" do
    post saved_recipes_url, params: { recipe_id: recipes(:pannkakor).id, collection_id: collections(:vardagsmat).id }
    assert_redirected_to new_session_path
  end

  test "saves a recipe to an existing collection and publishes it" do
    sign_in_as(users(:one))

    assert_difference "SavedRecipe.count", 1 do
      post saved_recipes_url, params: {
        recipe_id: recipes(:parsed_unpublished_recipe).id,
        collection_id: collections(:favoriter).id
      }
    end

    assert_redirected_to recipes(:parsed_unpublished_recipe)
    assert_predicate recipes(:parsed_unpublished_recipe).reload, :published?
  end

  test "responds with no content when saving silently" do
    sign_in_as(users(:one))

    post saved_recipes_url, params: {
      recipe_id: recipes(:parsed_unpublished_recipe).id,
      collection_id: collections(:favoriter).id,
      silent: "true"
    }

    assert_response :no_content
  end

  test "creates a new collection on the fly and saves the recipe into it" do
    sign_in_as(users(:one))

    assert_difference [ "Collection.count", "SavedRecipe.count" ], 1 do
      post saved_recipes_url, params: {
        recipe_id: recipes(:parsed_unpublished_recipe).id,
        collection_id: "new",
        new_collection_name: "Fredagsmys"
      }
    end

    assert_redirected_to recipes(:parsed_unpublished_recipe)
  end

  test "redirects with an alert when the new collection name is blank" do
    sign_in_as(users(:one))

    assert_no_difference [ "Collection.count", "SavedRecipe.count" ] do
      post saved_recipes_url, params: {
        recipe_id: recipes(:parsed_unpublished_recipe).id,
        collection_id: "new",
        new_collection_name: ""
      }
    end

    assert_redirected_to recipes(:parsed_unpublished_recipe)
  end

  test "redirects with an alert when the recipe is already saved in that collection" do
    sign_in_as(users(:one))

    assert_no_difference "SavedRecipe.count" do
      post saved_recipes_url, params: {
        recipe_id: recipes(:pannkakor).id,
        collection_id: collections(:vardagsmat).id
      }
    end

    assert_redirected_to recipes(:pannkakor)
  end

  test "removes a saved recipe" do
    sign_in_as(users(:one))

    assert_difference "SavedRecipe.count", -1 do
      delete saved_recipe_url(saved_recipes(:pannkakor_in_vardagsmat))
    end

    assert_response :no_content
  end

  test "404s when trying to remove another user's saved recipe" do
    sign_in_as(users(:two))

    assert_no_difference "SavedRecipe.count" do
      delete saved_recipe_url(saved_recipes(:pannkakor_in_vardagsmat))
    end

    assert_response :not_found
  end

  test "toggle removes the recipe when it's already saved in that collection" do
    sign_in_as(users(:one))

    assert_difference "SavedRecipe.count", -1 do
      post toggle_saved_recipe_url, params: {
        recipe_id: recipes(:pannkakor).id,
        collection_id: collections(:vardagsmat).id
      }
    end

    assert_response :no_content
  end

  test "toggle saves and publishes the recipe when it isn't saved yet" do
    sign_in_as(users(:one))

    assert_difference "SavedRecipe.count", 1 do
      post toggle_saved_recipe_url, params: {
        recipe_id: recipes(:parsed_unpublished_recipe).id,
        collection_id: collections(:favoriter).id
      }
    end

    assert_response :no_content
    assert_predicate recipes(:parsed_unpublished_recipe).reload, :published?
  end

  test "toggle allows a non-creator group member to save into a group collection" do
    sign_in_as(users(:three))

    assert_difference "SavedRecipe.count", 1 do
      post toggle_saved_recipe_url, params: {
        recipe_id: recipes(:parsed_unpublished_recipe).id,
        collection_id: collections(:private_group_favoriter).id
      }
    end

    assert_response :no_content
    assert_predicate recipes(:parsed_unpublished_recipe).reload, :published?
  end

  test "toggle removes a group collection's save regardless of who originally added it" do
    sign_in_as(users(:three))

    assert_difference "SavedRecipe.count", -1 do
      post toggle_saved_recipe_url, params: {
        recipe_id: recipes(:pannkakor).id,
        collection_id: collections(:private_group_favoriter).id
      }
    end

    assert_response :no_content
  end

  test "toggle 404s for a user outside the collection's group" do
    sign_in_as(users(:three))

    assert_no_difference "SavedRecipe.count" do
      post toggle_saved_recipe_url, params: {
        recipe_id: recipes(:pannkakor).id,
        collection_id: collections(:public_group_favoriter).id
      }
    end

    assert_response :not_found
  end
end
