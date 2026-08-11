require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the landing page to unauthenticated visitors" do
    get home_index_url
    assert_response :success
  end

  test "redirects authenticated users to explore" do
    sign_in_as(users(:one))
    get home_index_url
    assert_redirected_to explore_path
  end
end
