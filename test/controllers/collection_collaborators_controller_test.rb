require "test_helper"

class CollectionCollaboratorsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "be" }
    assert_redirected_to new_session_path
  end

  test "404s search for a signed-in non-owner" do
    sign_in_as(users(:two))

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "be" }

    assert_response :not_found
  end

  test "search matches by name or username, case-insensitively" do
    sign_in_as(users(:one))

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "DISA" }

    assert_response :success
    assert_match "Disa Dahlberg", response.body
  end

  test "search excludes the owner even when the query matches their name" do
    sign_in_as(users(:one))

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "Alice" }

    assert_response :success
    assert_no_match "Alice Andersson", response.body
  end

  test "search excludes existing collaborators even when the query matches their name" do
    sign_in_as(users(:one))

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "Bea" }
    assert_no_match "Bea Bengtsson", response.body

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "Otto" }
    assert_no_match "Otto Hansson", response.body
  end

  test "search requires at least 2 characters" do
    sign_in_as(users(:one))

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "d" }

    assert_response :success
    assert_no_match "Disa Dahlberg", response.body
  end

  test "search caps results at 8" do
    sign_in_as(users(:one))
    9.times { |n| User.create!(name: "Extra Person #{n}", username: "extra#{n}", email_address: "extra#{n}@example.com", password: "password") }

    get search_collection_collaborators_url(collections(:delad_collection)), params: { q: "extra" }

    assert_response :success
    assert_equal 8, response.body.scan("Extra Person").count
  end

  test "404s creating a collaborator for a signed-in non-owner" do
    sign_in_as(users(:two))

    assert_no_difference "CollectionCollaborator.count" do
      post collection_collaborators_url(collections(:delad_collection)), params: { user_id: users(:four).id }
    end

    assert_response :not_found
  end

  test "owner can add a collaborator, defaulting to the viewer role" do
    sign_in_as(users(:one))

    assert_difference "CollectionCollaborator.count", 1 do
      post collection_collaborators_url(collections(:delad_collection)), params: { user_id: users(:four).id }, as: :turbo_stream
    end

    assert_response :success
    assert collections(:delad_collection).collection_collaborators.find_by(user: users(:four)).viewer?
  end

  test "redirects after adding a collaborator for an html request" do
    sign_in_as(users(:one))

    post collection_collaborators_url(collections(:delad_collection)), params: { user_id: users(:four).id }

    assert_redirected_to collection_path(collections(:delad_collection))
  end

  test "fails to add a duplicate collaborator" do
    sign_in_as(users(:one))

    assert_no_difference "CollectionCollaborator.count" do
      post collection_collaborators_url(collections(:delad_collection)), params: { user_id: users(:two).id }, as: :turbo_stream
    end

    assert_response :unprocessable_content
  end

  test "redirects with an alert when adding a collaborator fails, for an html request" do
    sign_in_as(users(:one))

    post collection_collaborators_url(collections(:delad_collection)), params: { user_id: users(:one).id }

    assert_redirected_to collection_path(collections(:delad_collection))
    assert_equal "User är redan ägare", flash[:alert]
  end

  test "404s changing a role for a signed-in non-owner" do
    sign_in_as(users(:three))

    patch collection_collaborator_url(collections(:delad_collection), collection_collaborators(:two_viewer_on_delad)), params: { role: "editor" }

    assert_response :not_found
  end

  test "owner can change a collaborator's role" do
    sign_in_as(users(:one))

    patch collection_collaborator_url(collections(:delad_collection), collection_collaborators(:two_viewer_on_delad)), params: { role: "editor" }

    assert_response :no_content
    assert collection_collaborators(:two_viewer_on_delad).reload.editor?
  end

  test "404s changing the role of a collaborator that belongs to a different collection" do
    sign_in_as(users(:one))

    patch collection_collaborator_url(collections(:public_collection), collection_collaborators(:two_viewer_on_delad)), params: { role: "editor" }

    assert_response :not_found
  end

  test "404s removing a collaborator for a signed-in non-owner" do
    sign_in_as(users(:two))

    assert_no_difference "CollectionCollaborator.count" do
      delete collection_collaborator_url(collections(:delad_collection), collection_collaborators(:three_editor_on_delad))
    end

    assert_response :not_found
  end

  test "owner can remove a collaborator via turbo_stream" do
    sign_in_as(users(:one))

    assert_difference "CollectionCollaborator.count", -1 do
      delete collection_collaborator_url(collections(:delad_collection), collection_collaborators(:two_viewer_on_delad)), as: :turbo_stream
    end

    assert_response :success
  end

  test "redirects after removing a collaborator for an html request" do
    sign_in_as(users(:one))

    delete collection_collaborator_url(collections(:delad_collection), collection_collaborators(:three_editor_on_delad))

    assert_redirected_to collection_path(collections(:delad_collection))
  end
end
