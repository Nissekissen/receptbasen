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

  test "404s when a collaborator who isn't the owner tries to rename a collection" do
    sign_in_as(users(:three))

    patch collection_url(collections(:delad_collection)), params: { collection: { name: "Kapad" } }

    assert_response :not_found
    assert_equal "Delad med vänner", collections(:delad_collection).reload.name
  end

  test "404s when a collaborator who isn't the owner tries to destroy a collection" do
    sign_in_as(users(:three))

    assert_no_difference "Collection.count" do
      delete collection_url(collections(:delad_collection))
    end

    assert_response :not_found
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

  test "renaming a collection from its own show page redirects back there, not to the index" do
    sign_in_as(users(:one))

    patch collection_url(collections(:vardagsmat)),
      params: { collection: { name: "Helgmat" } },
      headers: { "HTTP_REFERER" => collection_url(collections(:vardagsmat)) }

    assert_redirected_to collection_path(collections(:vardagsmat))
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

  test "lists collections shared with the current user, separately from their own" do
    sign_in_as(users(:two))

    get collections_url

    assert_response :success
    assert_select ".collections--subtitle", "Delade med mig"
    assert_select ".collections--name", "Delad med vänner"
  end

  test "shows a role pill for an editor-shared collection on the index" do
    sign_in_as(users(:three))

    get collections_url

    assert_response :success
    assert_select ".collections--role", "Redigera"
  end

  test "shows no role pill for a viewer-shared collection on the index" do
    sign_in_as(users(:two))

    get collections_url

    assert_response :success
    assert_select ".collections--role", false
  end

  test "does not show the shared section when nothing is shared with the current user" do
    sign_in_as(users(:one))

    get collections_url

    assert_response :success
    assert_select ".collections--subtitle", false
  end

  test "owner can view their private collection's show page" do
    sign_in_as(users(:one))

    get collection_url(collections(:delad_collection))

    assert_response :success
    assert_select ".collection-show--title", "Delad med vänner"
    assert_select ".collection-show--role", "Ägare"
    assert_select ".collection-show--actions"
  end

  test "editor collaborator can view a shared collection's show page, without manage controls" do
    sign_in_as(users(:three))

    get collection_url(collections(:delad_collection))

    assert_response :success
    assert_select ".collection-show--role", "Redigera"
    assert_select ".collection-show--actions", false
    assert_select ".collection-show--owner", "Skapad av Alice Andersson"
  end

  test "viewer collaborator can view a shared collection's show page, with no role pill" do
    sign_in_as(users(:two))

    get collection_url(collections(:delad_collection))

    assert_response :success
    assert_select ".collection-show--badge", text: /PRIVAT/
    assert_select ".collection-show--role", false
  end

  test "404s a private collection for a signed-in user with no relationship to it" do
    sign_in_as(users(:four))

    get collection_url(collections(:delad_collection))

    assert_response :not_found
  end

  test "404s a private collection for an anonymous visitor" do
    get collection_url(collections(:delad_collection))

    assert_response :not_found
  end

  test "shows a public collection to an anonymous visitor" do
    get collection_url(collections(:public_collection))

    assert_response :success
    assert_select ".collection-show--badge", text: /PUBLIK/
  end

  test "shows the recipes saved in the collection, with attribution" do
    sign_in_as(users(:one))

    get collection_url(collections(:vardagsmat))

    assert_response :success
    assert_select ".recipe-preview--title", "Pannkakor"
    assert_select ".recipe-preview--attribution", "Sparad av Alice Andersson"
  end

  test "does not offer save/bookmark controls to an anonymous visitor" do
    get collection_url(collections(:public_collection))

    assert_response :success
    assert_select ".recipe-preview--save-wrap", false
  end
end
