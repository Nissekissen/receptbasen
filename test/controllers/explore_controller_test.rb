require "test_helper"

class ExploreControllerTest < ActionDispatch::IntegrationTest
  test "is reachable without authentication" do
    get explore_url
    assert_response :success
  end

  test "blank query shows no results section" do
    get explore_url
    assert_response :success
    assert_select ".explore-results", count: 0
  end

  test "search matches a recipe by title" do
    get explore_url(q: "pannkakor")
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:pannkakor).title
  end

  test "search matches a recipe by ingredient name" do
    Ingredient.create!(recipe: recipes(:pannkakor), content: "3 dl mjölk", name: "mjölk")

    get explore_url(q: "mjölk")
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:pannkakor).title
  end

  test "search excludes manual recipes even when the title matches" do
    get explore_url(q: recipes(:kottbullar).title)
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:kottbullar).title, count: 0
  end

  test "search excludes scraped recipes that haven't been published yet" do
    get explore_url(q: recipes(:parsed_unpublished_recipe).title)
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:parsed_unpublished_recipe).title, count: 0
  end

  test "search with no matches shows an empty state instead of an empty grid" do
    get explore_url(q: "finnsintealls")
    assert_response :success
    assert_select ".explore-results--empty"
    assert_select ".explore-results--grid", count: 0
  end

  test "shows the kök browse strip when at least one kök tag exists" do
    Tag.create!(name: "italienskt", category: :kok)

    get explore_url
    assert_response :success
    assert_select ".kok-strip--card", text: "Italienskt"
  end

  test "hides the kök browse strip when there are no kök tags yet" do
    get explore_url
    assert_response :success
    assert_select ".kok-strip", count: 0
  end

  test "kok_tag_id filters results to recipes tagged with that cuisine" do
    tag = Tag.create!(name: "italienskt", category: :kok)
    Tagging.create!(recipe: recipes(:pannkakor), tag: tag)

    get explore_url(kok_tag_id: tag.id)
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:pannkakor).title
  end

  test "kok_tag_id excludes recipes not tagged with that cuisine" do
    tag = Tag.create!(name: "italienskt", category: :kok)
    Tagging.create!(recipe: recipes(:pannkakor), tag: tag)

    get explore_url(kok_tag_id: tag.id)
    assert_response :success
    assert_select ".recipe-preview--title", text: recipes(:kottbullar).title, count: 0
  end

  test "shows exactly SHELVES_PER_PAGE shelves on the default page" do
    tag_pannkakor_for_every_shelf!

    get explore_url
    assert_response :success
    assert_select ".shelf", count: ExploreController::SHELVES_PER_PAGE
  end

  test "the shelf selection is stable across requests on the same day" do
    tag_pannkakor_for_every_shelf!

    get explore_url
    first_titles = css_select(".shelf--head h2").map(&:text)

    get explore_url
    second_titles = css_select(".shelf--head h2").map(&:text)

    assert_equal first_titles, second_titles
  end

  test "DISABLE_EXPLORE_SHELVES falls back to a flat popularity-ordered grid" do
    ENV["DISABLE_EXPLORE_SHELVES"] = "1"

    get explore_url
    assert_response :success
    assert_select ".shelf", count: 0
    assert_select ".explore-results--grid"
    assert_select ".recipe-preview--title", text: recipes(:pannkakor).title
  ensure
    ENV.delete("DISABLE_EXPLORE_SHELVES")
  end

  private

  # Tags pannkakor so every shelf_pool definition has at least one matching
  # recipe, regardless of which SHELVES_PER_PAGE entries the day's seed picks.
  def tag_pannkakor_for_every_shelf!
    recipe = recipes(:pannkakor)
    recipe.update!(total_time: "PT20M")

    recipe.tags << recipe.time_tag
    recipe.tags << Tag.find_or_create_by!(name: "middag") { |t| t.category = :maltidstyp }
    recipe.tags << Tag.find_or_create_by!(name: "bakverk") { |t| t.category = :maltidstyp }
    recipe.tags << Tag.find_or_create_by!(name: "frukost") { |t| t.category = :maltidstyp }
    recipe.tags << Tag.find_or_create_by!(name: "vegetariskt") { |t| t.category = :kost }
  end
end
