require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  setup do
    @svenskt = Tag.create!(name: "svenskt", category: :kok)
    @italienskt = Tag.create!(name: "italienskt", category: :kok)
  end

  test "prevents tagging a recipe with the same tag twice" do
    Tagging.create!(recipe: recipes(:pannkakor), tag: @svenskt)
    duplicate = Tagging.new(recipe: recipes(:pannkakor), tag: @svenskt)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end

  test "allows the same tag on different recipes" do
    Tagging.create!(recipe: recipes(:pannkakor), tag: @svenskt)
    other_recipe_tagging = Tagging.new(recipe: recipes(:kottbullar), tag: @svenskt)

    assert other_recipe_tagging.valid?
  end

  test "allows different tags on the same recipe" do
    Tagging.create!(recipe: recipes(:pannkakor), tag: @svenskt)
    second_tag = Tagging.new(recipe: recipes(:pannkakor), tag: @italienskt)

    assert second_tag.valid?
  end
end
