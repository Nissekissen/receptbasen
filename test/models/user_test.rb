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

  test "requires a username" do
    user = User.new(name: "Ny Person", email_address: "new@example.com")

    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
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
end
