require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "requires a name" do
    user = User.new(email_address: "new@example.com", password: "secret123")

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "downcases and strips username" do
    user = User.new(username: " Bengt_1 ")
    assert_equal("bengt_1", user.username)
  end

  test "auto-generates a username from the name when none is provided" do
    user = User.new(name: "Ny Person", email_address: "new@example.com", password: "secret123")

    assert user.valid?
    assert_equal "nyperson", user.username
  end

  test "auto-generated username falls back to a numeric suffix on collision" do
    User.create!(name: "Ny Person", email_address: "first@example.com", password: "secret123")
    second = User.new(name: "Ny Person", email_address: "second@example.com", password: "secret123")

    assert second.valid?
    assert_equal "nyperson2", second.username
  end

  test "auto-generated username falls back to 'user' when the name has no usable characters" do
    user = User.new(name: "!!!", email_address: "new@example.com", password: "secret123")

    assert user.valid?
    assert_equal "user", user.username
  end

  test "does not override a username that was already provided" do
    user = User.new(name: "Ny Person", email_address: "new@example.com", password: "secret123", username: "chosen")

    assert user.valid?
    assert_equal "chosen", user.username
  end

  test "requires a unique username" do
    user = User.new(name: "Ny Person", email_address: "new@example.com", username: users(:one).username)

    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "rejects a username with characters outside a-z0-9_" do
    user = User.new(name: "Ny Person", email_address: "new@example.com", username: "bengt ström!")

    assert_not user.valid?
    assert_includes user.errors[:username], "is invalid"
  end

  test "editable_shared_collections includes collections the user is an editor on" do
    assert_includes users(:three).editable_shared_collections, collections(:delad_collection)
  end

  test "editable_shared_collections excludes collections the user is only a viewer on" do
    assert_not_includes users(:two).editable_shared_collections, collections(:delad_collection)
  end

  test "editable_shared_collections excludes the user's own collections" do
    assert_not_includes users(:one).editable_shared_collections, collections(:delad_collection)
  end

  test "editable_shared_collections is empty for a user with no collaborations" do
    assert_empty users(:four).editable_shared_collections
  end
end
