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

  test "visible_to? is true for anyone when the recipe is in a public collection" do
    assert recipes(:manual_recipe_shared).visible_to?(users(:four))
  end

  # The regression case: the public-collection check has to run before the
  # nil-user bailout, or an anonymous visitor on a public profile would never
  # see a manual recipe there at all.
  test "visible_to? is true for a nil (anonymous) user when the recipe is in a public collection" do
    assert recipes(:manual_recipe_shared).visible_to?(nil)
  end

  test "visible_to? is true for a viewer collaborator on a collection containing the recipe" do
    assert recipes(:manual_recipe_collab_shared).visible_to?(users(:two))
  end

  test "visible_to? is true for an editor collaborator on a collection containing the recipe" do
    assert recipes(:manual_recipe_collab_shared).visible_to?(users(:three))
  end

  test "visible_to? is false for a user with no relationship to any collection containing the recipe" do
    assert_not recipes(:manual_recipe_collab_shared).visible_to?(users(:four))
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

  test "search matches a diacritic term" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/rakor", status: :done, published_at: 1.day.ago, title: "Räkor med aioli")

    assert_includes Recipe.search("räkor"), recipe
  end

  test "total_minutes prefers total_time over prep/cook time" do
    recipe = Recipe.new(total_time: "PT45M", prep_time: "PT10M", cook_time: "PT20M")
    assert_equal 45, recipe.total_minutes
  end

  test "total_minutes sums prep and cook time when there's no total_time" do
    recipe = Recipe.new(prep_time: "PT10M", cook_time: "PT20M")
    assert_equal 30, recipe.total_minutes
  end

  test "total_minutes works with only prep_time" do
    recipe = Recipe.new(prep_time: "PT15M")
    assert_equal 15, recipe.total_minutes
  end

  test "total_minutes works with only cook_time" do
    recipe = Recipe.new(cook_time: "PT15M")
    assert_equal 15, recipe.total_minutes
  end

  test "total_minutes returns nil when no time fields are set" do
    assert_nil Recipe.new.total_minutes
  end

  test "time_tag returns a snabbt tag for a quick recipe" do
    recipe = Recipe.new(total_time: "PT20M")
    tag = recipe.time_tag

    assert_equal "snabbt", tag.name
    assert_equal "tid", tag.category
  end

  test "time_tag returns snabbt at the 30 minute boundary" do
    assert_equal "snabbt", Recipe.new(total_time: "PT30M").time_tag.name
  end

  test "time_tag returns a långkok tag for a slow-cooked recipe" do
    tag = Recipe.new(total_time: "PT3H").time_tag

    assert_equal "långkok", tag.name
    assert_equal "tid", tag.category
  end

  test "time_tag returns långkok at the 120 minute boundary" do
    assert_equal "långkok", Recipe.new(total_time: "PT2H").time_tag.name
  end

  test "time_tag is nil for a recipe that's neither quick nor slow" do
    assert_nil Recipe.new(total_time: "PT45M").time_tag
  end

  test "time_tag is nil when there's no time data at all" do
    assert_nil Recipe.new.time_tag
  end

  test "time_tag reuses an existing tag instead of creating a duplicate" do
    existing = Tag.create!(name: "snabbt", category: :tid)

    assert_no_difference "Tag.count" do
      assert_equal existing, Recipe.new(total_time: "PT10M").time_tag
    end
  end

  test "apply_extracted_tags! creates and assigns tags from the extracted data" do
    recipe = recipes(:pannkakor)

    recipe.apply_extracted_tags!([
      { name: "efterrätt", category: :maltidstyp },
      { name: "svenskt", category: :kok }
    ])

    assert_equal %w[efterrätt svenskt], recipe.tags.pluck(:name).sort
  end

  test "apply_extracted_tags! also attaches the deterministic time tag when one applies" do
    recipe = recipes(:pannkakor)
    recipe.update!(total_time: "PT15M")

    recipe.apply_extracted_tags!([ { name: "frukost", category: :maltidstyp } ])

    assert_includes recipe.tags.pluck(:name), "snabbt"
  end

  test "apply_extracted_tags! doesn't choke when no time tag applies" do
    recipe = recipes(:pannkakor)
    recipe.update!(total_time: "PT45M")

    recipe.apply_extracted_tags!([ { name: "frukost", category: :maltidstyp } ])

    assert_equal %w[frukost], recipe.tags.pluck(:name)
  end

  test "apply_extracted_tags! replaces the recipe's existing tags rather than adding to them" do
    recipe = recipes(:pannkakor)
    recipe.tags << Tag.create!(name: "gammal-tagg", category: :maltidstyp)

    recipe.apply_extracted_tags!([ { name: "ny-tagg", category: :maltidstyp } ])

    assert_not_includes recipe.tags.pluck(:name), "gammal-tagg"
  end

  test "apply_extracted_tags! does nothing when given nil, as happens after a failed extraction" do
    recipe = recipes(:pannkakor)
    recipe.tags << Tag.create!(name: "befintlig", category: :maltidstyp)

    recipe.apply_extracted_tags!(nil)

    assert_equal %w[befintlig], recipe.tags.pluck(:name)
  end

  test "order_by_popularity ranks a recipe with recent cooks and saves above one with neither" do
    popular = Recipe.create!(source_url: "https://example.com/popular", status: :done, published_at: 1.day.ago, title: "Populär")
    quiet = Recipe.create!(source_url: "https://example.com/quiet", status: :done, published_at: 1.day.ago, title: "Tyst")

    CookLog.create!(user: users(:one), recipe: popular)
    SavedRecipe.create!(user: users(:one), collection: collections(:vardagsmat), recipe: popular)

    ordered = Recipe.catalog.order_by_popularity.to_a

    assert_operator ordered.index(popular), :<, ordered.index(quiet)
  end

  test "order_by_popularity respects the limit" do
    3.times { |i| Recipe.create!(source_url: "https://example.com/limit#{i}", status: :done, published_at: 1.day.ago, title: "R#{i}") }

    assert_equal 2, Recipe.catalog.order_by_popularity(2).to_a.size
  end

  test "order_by_cook_count ranks the most-cooked recipe first" do
    cooked = Recipe.create!(source_url: "https://example.com/cooked", status: :done, published_at: 1.day.ago, title: "Lagad")
    uncooked = Recipe.create!(source_url: "https://example.com/uncooked", status: :done, published_at: 1.day.ago, title: "Olagad")

    CookLog.create!(user: users(:one), recipe: cooked)
    CookLog.create!(user: users(:two), recipe: cooked)

    ordered = Recipe.catalog.order_by_cook_count.to_a

    assert_operator ordered.index(cooked), :<, ordered.index(uncooked)
  end
end
