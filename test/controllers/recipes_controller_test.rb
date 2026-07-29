require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  TAG_RESPONSE = {
    maltidstyp: "huvudrätt",
    kok: "svenskt",
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
end
