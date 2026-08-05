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
