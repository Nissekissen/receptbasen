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
end
