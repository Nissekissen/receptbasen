require "test_helper"

class RecipesHelperTest < ActionView::TestCase
  test "recipe_total_time prefers total_time over prep/cook time" do
    recipe = Recipe.new(total_time: "PT45M", prep_time: "PT10M", cook_time: "PT20M")
    assert_equal "45 min", recipe_total_time(recipe)
  end

  test "recipe_total_time sums prep and cook time when there's no total_time" do
    recipe = Recipe.new(prep_time: "PT10M", cook_time: "PT20M")
    assert_equal "30 min", recipe_total_time(recipe)
  end

  test "recipe_total_time works with only prep_time" do
    recipe = Recipe.new(prep_time: "PT15M")
    assert_equal "15 min", recipe_total_time(recipe)
  end

  test "recipe_total_time works with only cook_time" do
    recipe = Recipe.new(cook_time: "PT15M")
    assert_equal "15 min", recipe_total_time(recipe)
  end

  test "recipe_total_time returns nil when no time fields are set" do
    recipe = Recipe.new
    assert_nil recipe_total_time(recipe)
  end

  test "recipe_difficulty_icon maps known difficulties to their icon name" do
    assert_equal "easy", recipe_difficulty_icon("lätt")
    assert_equal "medium", recipe_difficulty_icon("medel")
    assert_equal "hard", recipe_difficulty_icon("avancerad")
  end

  test "recipe_difficulty_icon is case-insensitive" do
    assert_equal "easy", recipe_difficulty_icon("LÄTT")
  end

  test "recipe_difficulty_icon returns nil for an unknown difficulty" do
    assert_nil recipe_difficulty_icon("okänd")
  end

  test "recipe_difficulty_icon returns nil for nil" do
    assert_nil recipe_difficulty_icon(nil)
  end

  test "recipe_flow_step is ready for a done recipe" do
    assert_equal :ready, recipe_flow_step(recipes(:pannkakor))
  end

  test "recipe_flow_step is failed for a failed recipe" do
    assert_equal :failed, recipe_flow_step(recipes(:failed_recipe))
  end

  test "recipe_flow_step is working for a pending recipe" do
    assert_equal :working, recipe_flow_step(recipes(:pending_recipe))
  end

  test "recipe_difficulty capitalizes the svarighetsgrad tag's name" do
    tag = Tag.create!(name: "lätt", category: :svarighetsgrad)
    Tagging.create!(recipe: recipes(:pannkakor), tag: tag)

    assert_equal "Lätt", recipe_difficulty(recipes(:pannkakor))
  end

  test "recipe_difficulty is nil when the recipe has no svarighetsgrad tag" do
    assert_nil recipe_difficulty(recipes(:pannkakor))
  end

  test "step_duration_seconds parses minutes" do
    step = Step.new(content: "Koka i ca 5 minuter under lock.")
    assert_equal 300, step_duration_seconds(step)
  end

  test "step_duration_seconds parses the abbreviated min form" do
    step = Step.new(content: "Baka i ugn i 45 min.")
    assert_equal 2700, step_duration_seconds(step)
  end

  test "step_duration_seconds parses hours" do
    step = Step.new(content: "Låt degen jäsa i 2 timmar.")
    assert_equal 7200, step_duration_seconds(step)
  end

  test "step_duration_seconds parses a single hour" do
    step = Step.new(content: "Stek i ugn i 1 timme.")
    assert_equal 3600, step_duration_seconds(step)
  end

  test "step_duration_seconds takes the first number in a range" do
    step = Step.new(content: "Sjud i 5-10 minuter.")
    assert_equal 300, step_duration_seconds(step)
  end

  test "step_duration_seconds returns nil when there's no parseable duration" do
    step = Step.new(content: "Skala och skiva potatisarna.")
    assert_nil step_duration_seconds(step)
  end

  test "step_duration_seconds returns nil for a bare number with no time unit" do
    step = Step.new(content: "Tillsätt 5 potatisar.")
    assert_nil step_duration_seconds(step)
  end
end
