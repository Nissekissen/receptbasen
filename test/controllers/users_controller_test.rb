require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "signs up, logs in, and creates a locked Favoriter collection" do
    assert_difference [ "User.count", "Collection.count" ], 1 do
      post users_url, params: {
        user: {
          name: "Ny Användare",
          email_address: "ny@example.com",
          password: "secret123",
          password_confirmation: "secret123"
        }
      }
    end

    user = User.last
    assert_redirected_to root_url
    assert cookies[:session_id].present?

    collection = user.collections.sole
    assert_equal "Favoriter", collection.name
    assert_predicate collection, :locked?
  end

  test "re-renders the form without creating a user when signup is invalid" do
    assert_no_difference [ "User.count", "Collection.count" ] do
      post users_url, params: {
        user: {
          name: "",
          email_address: "ny@example.com",
          password: "secret123",
          password_confirmation: "secret123"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
