require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "prevents the same user from joining the same group twice" do
    duplicate = Membership.new(user: users(:two), group: groups(:private))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows the same user to belong to different groups" do
    membership = Membership.new(user: users(:three), group: groups(:public))

    assert membership.valid?
  end
end
