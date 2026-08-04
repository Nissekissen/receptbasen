require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "shows the join page for an active invite to an anonymous visitor" do
    get invite_url(invites(:private_active).token)

    assert_response :success
    assert_select "h1", text: /private group/
    assert_select "form[action=?]", join_group_path(groups(:private), token: invites(:private_active).token)
  end

  test "shows the join page to a signed-in non-member" do
    sign_in_as(users(:four))

    get invite_url(invites(:private_active).token)

    assert_response :success
    assert_select "form[action=?]", join_group_path(groups(:private), token: invites(:private_active).token)
  end

  test "redirects an existing member straight to the group" do
    sign_in_as(users(:one))

    get invite_url(invites(:private_active).token)

    assert_redirected_to group_path(groups(:private))
  end

  test "shows an invalid state for a revoked invite" do
    get invite_url(invites(:private_revoked).token)

    assert_response :success
    assert_select "form", count: 0
  end

  test "shows an invalid state for an unknown token" do
    get invite_url("does-not-exist")

    assert_response :success
    assert_select "form", count: 0
  end
end
