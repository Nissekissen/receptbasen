require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication to list groups" do
    get groups_url
    assert_redirected_to new_session_path
  end

  test "lists only the current user's groups" do
    sign_in_as(users(:one))

    get groups_url

    assert_response :success
    assert_select ".groups-index--card-name", text: "private group"
    assert_select ".groups-index--card-name", text: "public group"
  end

  test "does not list a group the user isn't a member of" do
    sign_in_as(users(:three))

    get groups_url

    assert_response :success
    assert_select ".groups-index--card-name", text: "private group"
    assert_select ".groups-index--card-name", text: "public group", count: 0
  end

  test "requires authentication to view the new group form" do
    get new_group_url
    assert_redirected_to new_session_path
  end

  test "creates a group along with the owner's membership and default collection" do
    sign_in_as(users(:one))

    assert_difference [ "Group.count", "Membership.count", "Collection.count" ], 1 do
      post groups_url, params: { group: { name: "Grillklubben", public: false } }
    end

    group = Group.last
    assert_redirected_to group
    assert_equal users(:one), group.owner

    membership = group.memberships.find_by(user: users(:one))
    assert membership.admin?

    collection = group.collections.find_by(name: "Favoriter")
    assert collection.locked?
    assert_equal users(:one), collection.user
  end

  test "does not create a group with a blank name" do
    sign_in_as(users(:one))

    assert_no_difference "Group.count" do
      post groups_url, params: { group: { name: "", public: false } }
    end

    assert_response :unprocessable_entity
  end

  test "shows a group's recipes scoped to its own collections" do
    sign_in_as(users(:one))

    get group_url(groups(:private))

    assert_response :success
    assert_select ".recipe-preview--title", text: "Pannkakor"
    assert_select ".recipe-preview--title", text: "Mormors köttbullar", count: 0
  end

  test "shows who saved a group recipe and into which collection" do
    sign_in_as(users(:one))

    get group_url(groups(:private))

    assert_select ".recipe-preview--attribution", text: /Bea Bengtsson/
  end

  test "filters a group's recipes by collection" do
    sign_in_as(users(:one))

    get group_url(groups(:private)), params: { collection_id: collections(:private_group_favoriter).id }

    assert_response :success
    assert_select ".recipe-preview--title", text: "Pannkakor"
  end

  test "shows the edit page to any group member" do
    sign_in_as(users(:two))

    get edit_group_url(groups(:private))

    assert_response :success
  end

  test "404s the edit page for a non-member" do
    sign_in_as(users(:three))

    get edit_group_url(groups(:public))

    assert_response :not_found
  end

  test "renames a group when the viewer is the owner" do
    sign_in_as(users(:one))

    patch group_url(groups(:private)), params: { group: { name: "Nytt namn" } }

    assert_redirected_to edit_group_path(groups(:private))
    assert_equal "Nytt namn", groups(:private).reload.name
  end

  test "allows a non-owner admin to rename the group" do
    sign_in_as(users(:three))

    patch group_url(groups(:private)), params: { group: { name: "Av Otto" } }

    assert_equal "Av Otto", groups(:private).reload.name
  end

  test "404s a plain member trying to rename the group" do
    sign_in_as(users(:two))

    patch group_url(groups(:private)), params: { group: { name: "Kapad" } }

    assert_response :not_found
    assert_equal "private group", groups(:private).reload.name
  end

  test "ignores an attempt to change visibility via update" do
    sign_in_as(users(:one))

    patch group_url(groups(:private)), params: { group: { name: "private group", public: true } }

    assert_not groups(:private).reload.public?
  end

  test "destroys a group as the owner, cascading its collections" do
    sign_in_as(users(:one))

    assert_difference [ "Group.count", "Collection.count" ], -1 do
      delete group_url(groups(:public))
    end

    assert_redirected_to groups_path
  end

  test "404s a non-owner admin trying to destroy the group" do
    sign_in_as(users(:three))

    assert_no_difference "Group.count" do
      delete group_url(groups(:private))
    end

    assert_response :not_found
  end

  test "shows a public group's page to an anonymous visitor" do
    get group_url(groups(:public))

    assert_response :success
  end

  test "shows the same join button to an anonymous visitor" do
    get group_url(groups(:public))

    assert_select "form[action=?]", join_group_path(groups(:public))
  end

  test "404s a private group for an anonymous visitor" do
    get group_url(groups(:private))

    assert_response :not_found
  end

  test "404s a private group for a signed-in non-member" do
    sign_in_as(users(:four))

    get group_url(groups(:private))

    assert_response :not_found
  end

  test "shows a join button to a signed-in non-member of a public group" do
    sign_in_as(users(:four))

    get group_url(groups(:public))

    assert_response :success
    assert_select "form[action=?]", join_group_path(groups(:public))
  end

  test "hides settings/invite controls from a non-member" do
    sign_in_as(users(:four))

    get group_url(groups(:public))

    assert_select ".group-show--settings", count: 0
  end

  test "shows settings/invite controls to a member" do
    sign_in_as(users(:one))

    get group_url(groups(:public))

    assert_select ".group-show--settings"
  end

  test "join creates a membership for an authenticated non-member of a public group" do
    sign_in_as(users(:four))

    assert_difference "Membership.count", 1 do
      post join_group_url(groups(:public))
    end

    assert groups(:public).member?(users(:four))
    assert_redirected_to groups(:public)
  end

  test "join is idempotent for an existing member" do
    sign_in_as(users(:one))

    assert_no_difference "Membership.count" do
      post join_group_url(groups(:public))
    end
  end

  test "404s joining a private group" do
    sign_in_as(users(:four))

    assert_no_difference "Membership.count" do
      post join_group_url(groups(:private))
    end

    assert_response :not_found
  end

  test "stashes a pending join and redirects to login for an anonymous visitor" do
    post join_group_url(groups(:public))

    assert_redirected_to login_path
    assert_equal groups(:public).id, session[:pending_group_join_id]
    assert_equal group_path(groups(:public)), session[:return_to_after_authenticating]
  end

  test "completes the pending join after logging in and returns to the group" do
    post join_group_url(groups(:public))

    post session_url, params: { email_address: users(:four).email_address, password: "password" }

    assert_redirected_to group_path(groups(:public))
    assert groups(:public).reload.member?(users(:four))
  end

  test "joins a private group with a valid invite token" do
    sign_in_as(users(:four))

    assert_difference "Membership.count", 1 do
      post join_group_url(groups(:private), token: invites(:private_active).token)
    end

    assert groups(:private).member?(users(:four))
    assert_redirected_to groups(:private)
  end

  test "404s joining a private group with a revoked invite token" do
    sign_in_as(users(:four))

    assert_no_difference "Membership.count" do
      post join_group_url(groups(:private), token: invites(:private_revoked).token)
    end

    assert_response :not_found
  end

  test "404s joining a private group with a token from a different group" do
    sign_in_as(users(:four))

    assert_no_difference "Membership.count" do
      post join_group_url(groups(:other_private), token: invites(:private_active).token)
    end

    assert_response :not_found
  end

  test "stashes a pending invite join and completes it after logging in" do
    post join_group_url(groups(:private), token: invites(:private_active).token)

    assert_redirected_to login_path
    assert_equal invites(:private_active).token, session[:pending_group_join_token]

    post session_url, params: { email_address: users(:four).email_address, password: "password" }

    assert_redirected_to group_path(groups(:private))
    assert groups(:private).reload.member?(users(:four))
  end
end
