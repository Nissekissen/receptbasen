require "test_helper"

class TagExtractorTest < ActiveSupport::TestCase
  test "creates one tag per maltidstyp value when a recipe spans multiple course types" do
    stub_anthropic_messages({
      maltidstyp: [ "efterrätt", "bakverk" ],
      kok: nil,
      kost: [],
      svarighetsgrad: "lätt"
    }.to_json)

    result = TagExtractor.new(title: "Kladdkaka", description: "En klassisk svensk kladdkaka.", ingredients: [ "ägg", "socker", "smör" ]).call

    assert_equal [ "efterrätt", "bakverk", "lätt" ], result.map { |tag| tag[:name] }
    assert_equal [ :maltidstyp, :maltidstyp, :svarighetsgrad ], result.map { |tag| tag[:category] }
  end

  test "creates one tag per kok value when a recipe is a genuine fusion" do
    stub_anthropic_messages({
      maltidstyp: [ "huvudrätt" ],
      kok: [ "asiatiskt", "amerikanskt" ],
      kost: [],
      svarighetsgrad: "medel"
    }.to_json)

    result = TagExtractor.new(title: "Asian fusion burger", description: "", ingredients: []).call

    assert_equal [ "huvudrätt", "asiatiskt", "amerikanskt", "medel" ], result.map { |tag| tag[:name] }
  end

  test "omits kok entirely when it's null" do
    stub_anthropic_messages({
      maltidstyp: [ "frukost" ],
      kok: nil,
      kost: [],
      svarighetsgrad: "lätt"
    }.to_json)

    result = TagExtractor.new(title: "Havregrynsgröt", description: "", ingredients: []).call

    assert_equal [ "frukost", "lätt" ], result.map { |tag| tag[:name] }
  end
end
