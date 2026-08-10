require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the landing page to authenticated users" do
    sign_in_as(users(:one))
    get home_index_url
    assert_response :success
  end

  test "redirects unauthenticated visitors to explore" do
    get home_index_url
    assert_redirected_to explore_path
  end
end
