require "test_helper"

class GroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  test "404s viewing the roster for a non-member" do
    sign_in_as(users(:three))

    get group_memberships_url(groups(:public))

    assert_response :not_found
  end

  test "lists members to any group member" do
    sign_in_as(users(:two))

    get group_memberships_url(groups(:private))

    assert_response :success
    assert_select ".member-name", text: "Alice Andersson"
    assert_select ".role-badge--owner", text: "Ägare"
  end

  test "shows promote/demote controls to the owner" do
    sign_in_as(users(:one))

    get group_memberships_url(groups(:private))

    assert_select ".collections--action", text: "Gör till admin"
  end

  test "hides promote/demote controls from a non-owner admin" do
    sign_in_as(users(:three))

    get group_memberships_url(groups(:private))

    assert_select ".collections--action", text: "Gör till admin", count: 0
  end

  test "owner can promote a member to admin" do
    sign_in_as(users(:one))
    membership = memberships(:two_in_private)

    patch group_membership_url(groups(:private), membership)

    assert membership.reload.admin?
  end

  test "owner can demote an admin" do
    sign_in_as(users(:one))
    membership = memberships(:non_owner_admin)

    patch group_membership_url(groups(:private), membership)

    assert_not membership.reload.admin?
  end

  test "404s a non-owner admin trying to promote another member" do
    sign_in_as(users(:three))
    membership = memberships(:two_in_private)

    patch group_membership_url(groups(:private), membership)

    assert_not membership.reload.admin?
    assert_response :not_found
  end

  test "404s trying to change the owner's own membership" do
    sign_in_as(users(:one))

    patch group_membership_url(groups(:private), memberships(:one_in_private))

    assert_response :not_found
  end

  test "a manager can remove a plain member" do
    sign_in_as(users(:three))

    assert_difference "Membership.count", -1 do
      delete group_membership_url(groups(:private), memberships(:two_in_private))
    end
  end

  test "a plain member cannot remove another member" do
    sign_in_as(users(:two))

    assert_no_difference "Membership.count" do
      delete group_membership_url(groups(:private), memberships(:non_owner_admin))
    end

    assert_response :not_found
  end

  test "the owner's membership can never be removed" do
    sign_in_as(users(:one))

    assert_no_difference "Membership.count" do
      delete group_membership_url(groups(:private), memberships(:one_in_private))
    end

    assert_response :not_found
  end
end
