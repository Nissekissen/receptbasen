require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "requires a name" do
    group = Group.new(owner: users(:one))

    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "is a member of group" do
    group = groups(:private)

    assert group.member?(users(:one))
  end

  test "is not a member of group" do
    group = groups(:public)

    assert_not group.member?(users(:three))
  end

  test "is manager and owner" do
    group = groups(:private)

    assert group.manager?(users(:one))
  end

  test "is manager but not owner" do
    group = groups(:private)

    assert group.manager?(users(:three))
  end

  test "is member but not manager" do
    group = groups(:private)

    assert_not group.manager?(users(:two))
  end

  test "is not member nor manager" do
    group = groups(:public)

    assert_not group.manager?(users(:three))
  end
end
