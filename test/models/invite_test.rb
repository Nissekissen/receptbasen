require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "generates a token on create" do
    invite = Invite.create!(group: groups(:private), created_by: users(:one))

    assert_not_nil invite.token
  end

  test "is active when not revoked" do
    assert invites(:private_active).active?
  end

  test "is not active when revoked" do
    assert_not invites(:private_revoked).active?
  end

  test "revoke! persists revoked_at" do
    invite = invites(:private_active)

    invite.revoke!

    assert_not invite.reload.active?
  end
end
