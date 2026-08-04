require "test_helper"

class GroupCollectionsControllerTest < ActionDispatch::IntegrationTest
  test "404s viewing collections for a non-member" do
    sign_in_as(users(:three))

    get group_collections_url(groups(:public))

    assert_response :not_found
  end

  test "lists a group's collections to any member" do
    sign_in_as(users(:two))

    get group_collections_url(groups(:private))

    assert_response :success
    assert_select ".collections--name", "Favoriter"
    assert_select ".collections--name", "Grillrecept"
  end

  test "shows rename/delete controls to a manager" do
    sign_in_as(users(:one))

    get group_collections_url(groups(:private))

    assert_select ".collections--action-delete"
  end

  test "hides rename/delete controls from a plain member" do
    sign_in_as(users(:two))

    get group_collections_url(groups(:private))

    assert_select ".collections--action-delete", count: 0
  end

  test "hides the Inbjudningar tab from a plain member" do
    sign_in_as(users(:two))

    get group_collections_url(groups(:private))

    assert_select ".settings-header--tab", text: "Inbjudningar", count: 0
  end

  test "shows the Inbjudningar tab to a manager" do
    sign_in_as(users(:one))

    get group_collections_url(groups(:private))

    assert_select ".settings-header--tab", text: "Inbjudningar"
  end

  test "creates a new collection as a manager" do
    sign_in_as(users(:one))

    assert_difference "Collection.count", 1 do
      post group_collections_url(groups(:private)), params: { collection: { name: "Nya recept" } }
    end

    assert_equal groups(:private), Collection.last.group
  end

  test "404s creating a collection for a plain member" do
    sign_in_as(users(:two))

    assert_no_difference "Collection.count" do
      post group_collections_url(groups(:private)), params: { collection: { name: "Fusk" } }
    end

    assert_response :not_found
  end

  test "renames an unlocked group collection as a manager" do
    sign_in_as(users(:three))

    patch group_collection_url(groups(:private), collections(:private_group_grillrecept)), params: { collection: { name: "Grillmys" } }

    assert_equal "Grillmys", collections(:private_group_grillrecept).reload.name
  end

  test "404s a plain member trying to rename a group collection" do
    sign_in_as(users(:two))

    patch group_collection_url(groups(:private), collections(:private_group_grillrecept)), params: { collection: { name: "Kapat" } }

    assert_response :not_found
  end

  test "destroys an unlocked group collection as a manager" do
    sign_in_as(users(:one))

    assert_difference "Collection.count", -1 do
      delete group_collection_url(groups(:private), collections(:private_group_grillrecept))
    end
  end

  test "prevents destroying the locked default collection" do
    sign_in_as(users(:one))

    assert_no_difference "Collection.count" do
      delete group_collection_url(groups(:private), collections(:private_group_favoriter))
    end
  end

  test "404s acting on a collection belonging to a different group" do
    sign_in_as(users(:one))

    patch group_collection_url(groups(:public), collections(:private_group_grillrecept)), params: { collection: { name: "Kapning" } }

    assert_response :not_found
  end
end
