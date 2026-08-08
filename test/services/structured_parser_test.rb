require "test_helper"

class StructuredParserTest < ActiveSupport::TestCase
  BASE_RECIPE = {
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
  }.freeze

  test "parses a well-formed recipe" do
    parser = StructuredParser.new(html_with(BASE_RECIPE))

    result = parser.call

    assert result
    assert_equal "Chokladbollar", result[:title]
    assert_equal "example.com", result[:source_domain]
    assert_equal [ "2 dl havregryn", "1 dl socker", "3 msk kakao" ], parser.ingredients
    assert_equal [ "Blanda alla ingredienser.", "Rulla till bollar och kyl." ], parser.steps
  end

  test "flattens instructions grouped under HowToSection" do
    recipe = BASE_RECIPE.merge(
      "recipeInstructions" => [
        {
          "@type" => "HowToSection",
          "name" => "Första steget",
          "itemListElement" => [
            { "@type" => "HowToStep", "text" => "Koka upp saltat vatten." },
            { "@type" => "HowToStep", "text" => "Tillsätt pastan." }
          ]
        }
      ]
    )

    parser = StructuredParser.new(html_with(recipe))

    assert parser.call
    assert_equal [ "Koka upp saltat vatten.", "Tillsätt pastan." ], parser.steps
  end

  test "bails when no recipe node is found" do
    html = "<html><body><p>Inget strukturerat recept här.</p></body></html>"

    assert_nil StructuredParser.new(html).call
  end

  test "bails when the recipe has no ingredients" do
    recipe = BASE_RECIPE.merge("recipeIngredient" => [])

    assert_nil StructuredParser.new(html_with(recipe)).call
  end

  test "bails when the recipe has no steps" do
    recipe = BASE_RECIPE.merge("recipeInstructions" => [])

    assert_nil StructuredParser.new(html_with(recipe)).call
  end

  test "bails when a HowToSection contains no usable steps" do
    recipe = BASE_RECIPE.merge(
      "recipeInstructions" => [
        { "@type" => "HowToSection", "name" => "Tomt avsnitt", "itemListElement" => [] }
      ]
    )

    assert_nil StructuredParser.new(html_with(recipe)).call
  end

  test "bails when none of the ingredients include an amount" do
    recipe = BASE_RECIPE.merge("recipeIngredient" => [ "Havregryn", "Socker", "Kakao" ])

    assert_nil StructuredParser.new(html_with(recipe)).call
  end

  test "does not bail when only some ingredients lack an amount" do
    recipe = BASE_RECIPE.merge("recipeIngredient" => [ "2 dl havregryn", "Salt efter smak" ])

    assert StructuredParser.new(html_with(recipe)).call
  end

  test "bails instead of raising when extraction encounters an error" do
    recipe = BASE_RECIPE.except("url", "image")

    assert_nil StructuredParser.new(html_with(recipe)).call
  end

  test "leaves external_rating and external_rating_count nil when there's no aggregateRating" do
    result = StructuredParser.new(html_with(BASE_RECIPE)).call

    assert_nil result[:external_rating]
    assert_nil result[:external_rating_count]
  end

  test "captures a rating that's already on a 1-5 scale as-is" do
    recipe = BASE_RECIPE.merge("aggregateRating" => { "ratingValue" => "4.5", "ratingCount" => "128" })

    result = StructuredParser.new(html_with(recipe)).call

    assert_equal 4.5, result[:external_rating]
    assert_equal 128, result[:external_rating_count]
  end

  test "normalizes a rating from a different scale onto 1-5" do
    recipe = BASE_RECIPE.merge(
      "aggregateRating" => { "ratingValue" => 8, "bestRating" => 10, "worstRating" => 0, "ratingCount" => 40 }
    )

    result = StructuredParser.new(html_with(recipe)).call

    assert_equal 4.2, result[:external_rating]
    assert_equal 40, result[:external_rating_count]
  end

  test "defaults bestRating/worstRating to 5/1 per schema.org when absent" do
    recipe = BASE_RECIPE.merge("aggregateRating" => { "ratingValue" => 3, "ratingCount" => 5 })

    result = StructuredParser.new(html_with(recipe)).call

    assert_equal 3.0, result[:external_rating]
  end

  test "falls back to reviewCount when ratingCount is absent" do
    recipe = BASE_RECIPE.merge("aggregateRating" => { "ratingValue" => 4, "reviewCount" => 12 })

    result = StructuredParser.new(html_with(recipe)).call

    assert_equal 12, result[:external_rating_count]
  end

  test "leaves the rating nil when bestRating and worstRating are equal" do
    recipe = BASE_RECIPE.merge(
      "aggregateRating" => { "ratingValue" => 5, "bestRating" => 5, "worstRating" => 5, "ratingCount" => 3 }
    )

    result = StructuredParser.new(html_with(recipe)).call

    assert_nil result[:external_rating]
    assert_nil result[:external_rating_count]
  end

  test "leaves the rating nil when ratingValue is missing entirely" do
    recipe = BASE_RECIPE.merge("aggregateRating" => { "ratingCount" => 50 })

    result = StructuredParser.new(html_with(recipe)).call

    assert_nil result[:external_rating]
  end

  private

  def html_with(recipe)
    <<~HTML
      <html>
        <head>
          <script type="application/ld+json">
            #{recipe.to_json}
          </script>
        </head>
        <body></body>
      </html>
    HTML
  end
end
