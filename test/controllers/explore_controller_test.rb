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
end
