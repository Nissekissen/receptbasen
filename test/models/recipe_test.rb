require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  test "normalizes source_url by removing tracking params" do
    recipe = Recipe.new(source_url: "https://example.com/recipe?utm_source=newsletter&fbclid=abc123")
    assert_equal "https://example.com/recipe", recipe.source_url
  end

  test "normalizes source_url by keeping non-tracking query params" do
    recipe = Recipe.new(source_url: "https://example.com/recipe?servings=4&utm_source=newsletter")
    assert_equal "https://example.com/recipe?servings=4", recipe.source_url
  end

  test "normalizes source_url by downcasing and stripping www from the host" do
    recipe = Recipe.new(source_url: "https://WWW.Example.COM/recipe")
    assert_equal "https://example.com/recipe", recipe.source_url
  end

  test "normalizes source_url by stripping trailing slashes" do
    recipe = Recipe.new(source_url: "https://example.com/recipe///")
    assert_equal "https://example.com/recipe", recipe.source_url
  end

  test "normalizes source_url by dropping the fragment" do
    recipe = Recipe.new(source_url: "https://example.com/recipe#instructions")
    assert_equal "https://example.com/recipe", recipe.source_url
  end

  test "leaves an unparseable source_url unchanged instead of raising" do
    recipe = Recipe.new(source_url: "not a url")
    assert_equal "not a url", recipe.source_url
  end

  test "leaves a nil source_url as nil" do
    recipe = Recipe.new(source_url: nil)
    assert_nil recipe.source_url
  end

  test "normalizes source_domain to the registrable domain, stripping subdomains" do
    recipe = Recipe.new(source_domain: "blog.cooking.example.com")
    assert_equal "example.com", recipe.source_domain
  end

  test "normalizes source_domain by downcasing" do
    recipe = Recipe.new(source_domain: "WWW.Example.CO.UK")
    assert_equal "example.co.uk", recipe.source_domain
  end

  test "manual? is true when the recipe has an owner" do
    recipe = Recipe.new(owner_id: users(:one).id)
    assert recipe.manual?
  end

  test "manual? is false for a scraped recipe" do
    recipe = Recipe.new(source_url: "https://example.com/recipe")
    assert_not recipe.manual?
  end

  test "published? is false without a published_at" do
    assert_not recipes(:pending_recipe).published?
  end

  test "published? is true once published_at is set" do
    assert recipes(:pannkakor).published?
  end

  test "publish! sets published_at and persists it" do
    recipe = recipes(:pending_recipe)

    assert_changes -> { recipe.reload.published_at }, from: nil do
      recipe.publish!
    end

    assert recipe.published?
  end

  test "requires a source_url for a scraped (non-manual) recipe" do
    recipe = Recipe.new(source_url: nil, owner_id: nil)

    assert_not recipe.valid?
    assert_includes recipe.errors[:source_url], "can't be blank"
  end

  test "does not require a source_url for a manual recipe" do
    recipe = Recipe.new(owner_id: users(:one).id, title: "Hemlagad soppa")

    recipe.valid?

    assert_empty recipe.errors[:source_url]
  end

  test "rejects a recipe with both an owner and a source_url" do
    recipe = Recipe.new(owner_id: users(:one).id, source_url: "https://example.com/recipe")

    assert_not recipe.valid?
    assert_includes recipe.errors[:owner_id], "must be blank"
  end

  test "rejects a duplicate source_url" do
    recipe = Recipe.new(source_url: recipes(:pannkakor).source_url)

    assert_not recipe.valid?
    assert_includes recipe.errors[:source_url], "has already been taken"
  end

  test "allows multiple manual recipes with no source_url" do
    recipe = Recipe.new(owner_id: users(:one).id, title: "En till soppa")

    recipe.valid?

    assert_empty recipe.errors[:source_url]
  end

  test "visible_to? is true for anyone on a scraped recipe" do
    assert recipes(:pannkakor).visible_to?(users(:two))
    assert recipes(:pannkakor).visible_to?(nil)
  end

  test "visible_to? is true for a manual recipe's owner" do
    assert recipes(:kottbullar).visible_to?(users(:one))
  end

  test "visible_to? is false for a non-owner with no relationship to the recipe" do
    assert_not recipes(:kottbullar).visible_to?(users(:two))
  end

  test "visible_to? is false for an anonymous visitor on a manual recipe" do
    assert_not recipes(:kottbullar).visible_to?(nil)
  end

  test "visible_to? is true for a fellow group member once the recipe is saved in a group collection" do
    assert recipes(:manual_recipe_in_group).visible_to?(users(:one))
  end

  test "visible_to? is false for a user outside the group the recipe was saved into" do
    assert_not recipes(:manual_recipe_in_group).visible_to?(users(:three))
  end

  test "catalog includes done, unowned, published recipes" do
    assert_includes Recipe.catalog, recipes(:pannkakor)
  end

  test "catalog excludes recipes that are still pending" do
    assert_not_includes Recipe.catalog, recipes(:pending_recipe)
  end

  test "catalog excludes recipes whose parse failed" do
    assert_not_includes Recipe.catalog, recipes(:failed_recipe)
  end

  test "catalog excludes done recipes that haven't been published yet" do
    assert_not_includes Recipe.catalog, recipes(:parsed_unpublished_recipe)
  end

  test "catalog excludes manual recipes even when published_at is set" do
    assert_not_includes Recipe.catalog, recipes(:kottbullar)
  end

  test "search returns everything when the query is blank" do
    assert_equal Recipe.count, Recipe.search("").count
    assert_equal Recipe.count, Recipe.search(nil).count
  end

  test "search matches recipes by title, case-insensitively" do
    assert_includes Recipe.search("PANNKAKOR"), recipes(:pannkakor)
  end

  test "search matches recipes by ingredient name or content" do
    Ingredient.create!(recipe: recipes(:kottbullar), content: "500 g nötfärs", name: "nötfärs")

    assert_includes Recipe.search("nötfärs"), recipes(:kottbullar)
  end

  test "search does not match recipes with unrelated ingredients" do
    Ingredient.create!(recipe: recipes(:kottbullar), content: "500 g nötfärs", name: "nötfärs")

    assert_not_includes Recipe.search("lax"), recipes(:kottbullar)
  end

  test "search ANDs multiple terms together" do
    Ingredient.create!(recipe: recipes(:pannkakor), content: "3 dl mjölk", name: "mjölk")

    assert_includes Recipe.search("pannkakor mjölk"), recipes(:pannkakor)
    assert_not_includes Recipe.search("pannkakor lök"), recipes(:pannkakor)
  end
end
