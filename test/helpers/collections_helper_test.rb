require "test_helper"

class CollectionsHelperTest < ActionView::TestCase
  FakeCollection = Struct.new(:name, :recipes_count)

  test "collection_count_label shows Tomt for an empty collection" do
    collection = FakeCollection.new(nil, 0)
    assert_equal "Tomt", collection_count_label(collection)
  end

  test "collection_count_label shows the count for a non-empty collection" do
    collection = FakeCollection.new(nil, 3)
    assert_equal "3 recept", collection_count_label(collection)
  end

  test "collection_delete_confirm is nil for an empty collection" do
    collection = FakeCollection.new("Vardagsmat", 0)
    assert_nil collection_delete_confirm(collection)
  end

  test "collection_delete_confirm uses singular phrasing for one recipe" do
    collection = FakeCollection.new("Vardagsmat", 1)

    assert_equal(
      "Ta bort \"Vardagsmat\" och 1 sparat recept i den? Recepten finns kvar i Receptbasen, men du behöver spara dem igen.",
      collection_delete_confirm(collection)
    )
  end

  test "collection_delete_confirm uses plural phrasing for multiple recipes" do
    collection = FakeCollection.new("Vardagsmat", 3)

    assert_equal(
      "Ta bort \"Vardagsmat\" och 3 sparade recept i den? Recepten finns kvar i Receptbasen, men du behöver spara dem igen.",
      collection_delete_confirm(collection)
    )
  end

  test "collection_role_label is Ägare for the owner" do
    assert_equal "Ägare", collection_role_label(collections(:delad_collection), users(:one))
  end

  test "collection_role_label is Redigera for an editor collaborator" do
    assert_equal "Redigera", collection_role_label(collections(:delad_collection), users(:three))
  end

  test "collection_role_label is Visa for a viewer collaborator" do
    assert_equal "Visa", collection_role_label(collections(:delad_collection), users(:two))
  end

  test "collection_role_label is nil for a user with no relationship to the collection" do
    assert_nil collection_role_label(collections(:delad_collection), users(:four))
  end

  test "collection_role_label is nil for a nil user" do
    assert_nil collection_role_label(collections(:delad_collection), nil)
  end
end
