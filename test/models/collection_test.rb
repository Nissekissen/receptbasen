require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "requires a name" do
    collection = Collection.new(user: users(:one))

    assert_not collection.valid?
    assert_includes collection.errors[:name], "can't be blank"
  end

  test "prevents destroying a locked collection" do
    collection = collections(:favoriter)

    assert_no_difference -> { Collection.count } do
      assert_not collection.destroy
    end
  end

  test "allows destroying an unlocked collection" do
    collection = collections(:vardagsmat)

    assert_difference -> { Collection.count }, -1 do
      assert collection.destroy
    end
  end

  test "prevents renaming a locked collection" do
    collection = collections(:favoriter)

    assert_not collection.update(name: "Nytt namn")
    assert_equal "Favoriter", collection.reload.name
  end

  test "allows updating a locked collection's other attributes" do
    collection = collections(:favoriter)

    assert collection.update(locked: false)
  end

  test "recipes_count falls back to counting saved_recipes when not preloaded" do
    assert_equal 1, Collection.find(collections(:vardagsmat).id).recipes_count
    assert_equal 0, Collection.find(collections(:favoriter).id).recipes_count
  end

  test "recipes_count prefers a preloaded count over querying" do
    collection = Collection.select("collections.*, 999 AS recipes_count").find(collections(:vardagsmat).id)

    assert_equal 999, collection.recipes_count
  end

  test "accessible_to? is true for the collection's own user" do
    assert collections(:vardagsmat).accessible_to?(users(:one))
  end

  test "accessible_to? is false for a personal collection's non-owner" do
    assert_not collections(:vardagsmat).accessible_to?(users(:two))
  end

  test "accessible_to? is false for a nil user" do
    assert_not collections(:vardagsmat).accessible_to?(nil)
  end

  test "accessible_to? is true for a public collection, even for an unrelated user" do
    assert collections(:public_collection).accessible_to?(users(:four))
  end

  test "accessible_to? is true for a public collection, even for a nil user" do
    assert collections(:public_collection).accessible_to?(nil)
  end

  test "accessible_to? is true for a viewer collaborator" do
    assert collections(:delad_collection).accessible_to?(users(:two))
  end

  test "accessible_to? is true for an editor collaborator" do
    assert collections(:delad_collection).accessible_to?(users(:three))
  end

  test "accessible_to? is false for a user with no relationship to a private collection" do
    assert_not collections(:delad_collection).accessible_to?(users(:four))
  end

  test "editable_by? is true for the owner" do
    assert collections(:delad_collection).editable_by?(users(:one))
  end

  test "editable_by? is true for an editor collaborator" do
    assert collections(:delad_collection).editable_by?(users(:three))
  end

  test "editable_by? is false for a viewer collaborator" do
    assert_not collections(:delad_collection).editable_by?(users(:two))
  end

  test "editable_by? is false for a nil user" do
    assert_not collections(:delad_collection).editable_by?(nil)
  end

  test "owned_by? is true for the owner" do
    assert collections(:delad_collection).owned_by?(users(:one))
  end

  test "owned_by? is false for a collaborator" do
    assert_not collections(:delad_collection).owned_by?(users(:three))
  end
end
