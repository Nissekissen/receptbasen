require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
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
end
