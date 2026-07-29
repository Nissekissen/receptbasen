require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get collections_url
    assert_redirected_to new_session_path
  end

  test "lists the current user's collections with locked ones first" do
    sign_in_as(users(:one))

    get collections_url

    assert_response :success
    assert_select ".collections--name", "Favoriter"
    assert_select ".collections--name", "Vardagsmat"
    assert_operator response.body.index("Favoriter"), :<, response.body.index("Vardagsmat")
  end

  test "creates a new collection" do
    sign_in_as(users(:one))

    assert_difference "Collection.count", 1 do
      post collections_url, params: { collection: { name: "Helger" } }
    end

    assert_redirected_to collections_path
    follow_redirect!
    assert_select ".collections--notice", "Samlingen skapades."
  end

  test "does not create a collection with a blank name" do
    sign_in_as(users(:one))

    assert_no_difference "Collection.count" do
      post collections_url, params: { collection: { name: "" } }
    end

    assert_redirected_to collections_path
  end

  test "renames an unlocked collection" do
    sign_in_as(users(:one))

    patch collection_url(collections(:vardagsmat)), params: { collection: { name: "Helgmat" } }

    assert_redirected_to collections_path
    assert_equal "Helgmat", collections(:vardagsmat).reload.name
  end

  test "prevents renaming a locked collection" do
    sign_in_as(users(:one))

    patch collection_url(collections(:favoriter)), params: { collection: { name: "Nytt namn" } }

    assert_redirected_to collections_path
    assert_equal "Favoriter", collections(:favoriter).reload.name
  end

  test "destroys an unlocked collection" do
    sign_in_as(users(:one))

    assert_difference "Collection.count", -1 do
      delete collection_url(collections(:vardagsmat))
    end

    assert_redirected_to collections_path
  end

  test "prevents destroying a locked collection" do
    sign_in_as(users(:one))

    assert_no_difference "Collection.count" do
      delete collection_url(collections(:favoriter))
    end

    assert_redirected_to collections_path
  end

  test "404s when trying to update another user's collection" do
    sign_in_as(users(:one))

    patch collection_url(collections(:two_favoriter)), params: { collection: { name: "Kapad" } }

    assert_response :not_found
  end

  test "404s when trying to destroy another user's collection" do
    sign_in_as(users(:one))

    assert_no_difference "Collection.count" do
      delete collection_url(collections(:two_favoriter))
    end

    assert_response :not_found
  end
end
