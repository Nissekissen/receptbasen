require "test_helper"

class GroupInvitesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get group_invites_url(groups(:private))

    assert_redirected_to new_session_path
  end

  test "404s listing invites for a plain member" do
    sign_in_as(users(:two))

    get group_invites_url(groups(:private))

    assert_response :not_found
  end

  test "lists active invites to a manager, excluding revoked ones" do
    sign_in_as(users(:one))

    get group_invites_url(groups(:private))

    assert_response :success
    assert_select ".invite-link-field[value=?]", invite_url(invites(:private_active).token)
    assert_select ".invite-link-field[value=?]", invite_url(invites(:private_revoked).token), count: 0
  end

  test "a non-owner admin can also view and manage invites" do
    sign_in_as(users(:three))

    get group_invites_url(groups(:private))

    assert_response :success
  end

  test "creates an invite as a manager" do
    sign_in_as(users(:one))

    assert_difference "Invite.count", 1 do
      post group_invites_url(groups(:private))
    end

    assert_equal users(:one), Invite.last.created_by
    assert_redirected_to group_invites_path(groups(:private))
  end

  test "404s creating an invite for a plain member" do
    sign_in_as(users(:two))

    assert_no_difference "Invite.count" do
      post group_invites_url(groups(:private))
    end

    assert_response :not_found
  end

  test "revokes an invite as a manager without destroying the row" do
    sign_in_as(users(:one))

    assert_no_difference "Invite.count" do
      delete group_invite_url(groups(:private), invites(:private_active))
    end

    assert_not invites(:private_active).reload.active?
  end

  test "404s revoking an invite for a plain member" do
    sign_in_as(users(:two))

    delete group_invite_url(groups(:private), invites(:private_active))

    assert_response :not_found
    assert invites(:private_active).reload.active?
  end

  test "404s acting on an invite belonging to a different group" do
    sign_in_as(users(:one))

    delete group_invite_url(groups(:public), invites(:private_active))

    assert_response :not_found
    assert invites(:private_active).reload.active?
  end
end
