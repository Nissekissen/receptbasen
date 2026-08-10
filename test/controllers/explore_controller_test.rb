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
end
