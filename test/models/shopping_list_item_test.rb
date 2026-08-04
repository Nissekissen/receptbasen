require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  test "requires content" do
    item = ShoppingListItem.new(user: users(:one))

    assert_not item.valid?
    assert_includes item.errors[:content], "can't be blank"
  end

  test "recipe is optional" do
    item = ShoppingListItem.new(user: users(:one), content: "Mjölk")

    assert item.valid?
  end
end
