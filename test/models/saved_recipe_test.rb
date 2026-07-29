require "test_helper"

class SavedRecipeTest < ActiveSupport::TestCase
  test "prevents saving the same recipe twice in the same collection" do
    saved_recipe = SavedRecipe.new(
      user: users(:one),
      collection: collections(:vardagsmat),
      recipe: recipes(:pannkakor)
    )

    assert_not saved_recipe.valid?
    assert_includes saved_recipe.errors[:recipe_id], "has already been taken"
  end

  test "allows the same recipe in two different collections" do
    saved_recipe = SavedRecipe.new(
      user: users(:one),
      collection: collections(:favoriter),
      recipe: recipes(:pannkakor)
    )

    assert saved_recipe.valid?
  end

  test "allows two different users to each save the same recipe to their own collections" do
    saved_recipe = SavedRecipe.new(
      user: users(:two),
      collection: collections(:two_favoriter),
      recipe: recipes(:pannkakor)
    )

    assert saved_recipe.valid?
  end
end
