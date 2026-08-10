require "test_helper"

class ParseRecipeJobTest < ActiveJob::TestCase
  STRUCTURED_HTML = <<~HTML
    <html>
      <head>
        <script type="application/ld+json">
          #{{
            "@context" => "https://schema.org",
            "@type" => "Recipe",
            "name" => "Chokladbollar",
            "description" => "Enkla chokladbollar utan bakning.",
            "image" => "https://example.com/chokladbollar.jpg",
            "prepTime" => "PT15M",
            "cookTime" => "PT0M",
            "recipeYield" => "20 bollar",
            "recipeIngredient" => [ "2 dl havregryn", "1 dl socker", "3 msk kakao" ],
            "recipeInstructions" => [
              { "@type" => "HowToStep", "text" => "Blanda alla ingredienser." },
              { "@type" => "HowToStep", "text" => "Rulla till bollar och kyl." }
            ],
            "url" => "https://example.com/recept/chokladbollar"
          }.to_json}
        </script>
      </head>
      <body></body>
    </html>
  HTML

  PLAIN_HTML = "<html><body><p>Inget strukturerat recept här.</p></body></html>".freeze

  TAG_RESPONSE = {
    maltidstyp: [ "efterrätt" ],
    kok: nil,
    kost: [ "vegetariskt" ],
    svarighetsgrad: "lätt"
  }.to_json

  LLM_RECIPE_RESPONSE = {
    is_recipe: true,
    title: "Enkel pasta",
    description: "Snabb vardagsmat",
    image_url: "https://example.com/pasta.jpg",
    prep_time: "PT10M",
    cook_time: "PT15M",
    total_time: nil,
    servings: "4",
    source_domain: "example.com",
    ingredients: [ "Pasta", "Tomatsås" ],
    steps: [ "Koka pastan", "Värm såsen" ]
  }.to_json

  INGREDIENT_SPLIT_RESPONSE = {
    ingredients: [
      { quantity: "2", unit: "dl", name: "havregryn" },
      { quantity: "1", unit: "dl", name: "socker" },
      { quantity: "3", unit: "msk", name: "kakao" }
    ]
  }.to_json

  PASTA_INGREDIENT_SPLIT_RESPONSE = {
    ingredients: [
      { quantity: nil, unit: nil, name: "Pasta" },
      { quantity: nil, unit: nil, name: "Tomatsås" }
    ]
  }.to_json

  test "parses structured recipe data without calling the LLM parser" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/chokladbollar", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 200, body: STRUCTURED_HTML)
    stub_anthropic_messages(INGREDIENT_SPLIT_RESPONSE, TAG_RESPONSE)

    ParseRecipeJob.perform_now(recipe.id)
    recipe.reload

    assert_predicate recipe, :done?
    assert_equal "Chokladbollar", recipe.title
    assert_equal [ "2 dl havregryn", "1 dl socker", "3 msk kakao" ], recipe.ingredients.map(&:content)
    assert_equal [ "2", "1", "3" ], recipe.ingredients.map(&:quantity)
    assert_equal [ "dl", "dl", "msk" ], recipe.ingredients.map(&:unit)
    assert_equal [ "havregryn", "socker", "kakao" ], recipe.ingredients.map(&:name)
    assert_equal [ "Blanda alla ingredienser.", "Rulla till bollar och kyl." ], recipe.steps.order(:position).map(&:content)
    assert_equal [ "efterrätt", "vegetariskt", "lätt" ], recipe.tags.map(&:name)
    assert_requested :post, "https://api.anthropic.com/v1/messages", times: 2
  end

  test "still saves the recipe when ingredient splitting fails" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/chokladbollar", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 200, body: STRUCTURED_HTML)
    mismatched_count_response = { ingredients: [ { quantity: "2", unit: "dl", name: "havregryn" } ] }.to_json
    stub_anthropic_messages(mismatched_count_response, TAG_RESPONSE)

    ParseRecipeJob.perform_now(recipe.id)
    recipe.reload

    assert_predicate recipe, :done?
    assert_equal [ "2 dl havregryn", "1 dl socker", "3 msk kakao" ], recipe.ingredients.map(&:content)
    assert recipe.ingredients.all? { |ingredient| ingredient.name.nil? }
  end

  test "falls back to the LLM parser when there's no structured data" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/pasta", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 200, body: PLAIN_HTML)
    stub_anthropic_messages(LLM_RECIPE_RESPONSE, PASTA_INGREDIENT_SPLIT_RESPONSE, TAG_RESPONSE)

    ParseRecipeJob.perform_now(recipe.id)
    recipe.reload

    assert_predicate recipe, :done?
    assert_equal "Enkel pasta", recipe.title
    assert_equal [ "Pasta", "Tomatsås" ], recipe.ingredients.map(&:content)
    assert_equal [ "Pasta", "Tomatsås" ], recipe.ingredients.map(&:name)
    assert_equal [ "Koka pastan", "Värm såsen" ], recipe.steps.order(:position).map(&:content)
    assert_requested :post, "https://api.anthropic.com/v1/messages", times: 3
  end

  test "marks the recipe failed when the page can't be fetched" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/404", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 500)

    ParseRecipeJob.perform_now(recipe.id)

    assert_predicate recipe.reload, :failed?
  end

  test "marks the recipe failed when the LLM says the page isn't a recipe" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/blogpost", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 200, body: PLAIN_HTML)
    stub_anthropic_messages({ is_recipe: false }.to_json)

    ParseRecipeJob.perform_now(recipe.id)

    assert_predicate recipe.reload, :failed?
    assert_requested :post, "https://api.anthropic.com/v1/messages", times: 1
  end

  test "marks the recipe failed when the LLM finds no ingredients or steps" do
    recipe = Recipe.create!(source_url: "https://example.com/recept/tomt", status: :pending)
    stub_request(:get, recipe.source_url).to_return(status: 200, body: PLAIN_HTML)
    stub_anthropic_messages({ is_recipe: true, title: "Tomt recept", ingredients: [], steps: [] }.to_json)

    ParseRecipeJob.perform_now(recipe.id)

    assert_predicate recipe.reload, :failed?
  end
end
