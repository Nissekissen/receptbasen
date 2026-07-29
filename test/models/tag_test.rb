require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "requires a name" do
    tag = Tag.new(category: :kost)

    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "requires a category" do
    tag = Tag.new(name: "vegetariskt")

    assert_not tag.valid?
    assert_includes tag.errors[:category], "can't be blank"
  end

  test "requires a unique name" do
    Tag.create!(name: "vegetariskt", category: :kost)
    duplicate = Tag.new(name: "vegetariskt", category: :kok)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
