require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get profile_url
    assert_redirected_to new_session_path
  end

  test "shows the current user's profile" do
    sign_in_as(users(:one))

    get profile_url

    assert_response :success
  end

  test "shows the theme picker with all three options" do
    sign_in_as(users(:one))

    get profile_url

    assert_select ".theme-picker--option", "Ljust"
    assert_select ".theme-picker--option", "Mörkt"
    assert_select ".theme-picker--option", "System"
  end

  test "updates the current user's username" do
    sign_in_as(users(:one))

    patch profile_url, params: { user: { username: "alice2" } }

    assert_redirected_to profile_path
    assert_equal "alice2", users(:one).reload.username
  end

  test "rejects a duplicate username" do
    sign_in_as(users(:one))

    patch profile_url, params: { user: { username: users(:two).username } }

    assert_redirected_to profile_path
    assert_not_equal users(:two).username, users(:one).reload.username
  end
end
