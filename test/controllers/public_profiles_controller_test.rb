require "test_helper"

class PublicProfilesControllerTest < ActionDispatch::IntegrationTest
  test "shows a user's public collections, logged out" do
    get public_profile_url(users(:one).username)

    assert_response :success
    assert_select ".public-profile--name", "Alice Andersson"
    assert_select ".public-profile--handle", "@alice"
    assert_select ".public-profile--card-name", "Publika favoriter"
  end

  test "does not show private or shared collections" do
    get public_profile_url(users(:one).username)

    assert_response :success
    assert_select ".public-profile--card-name", text: "Vardagsmat", count: 0
    assert_select ".public-profile--card-name", text: "Delad med vänner", count: 0
  end

  test "shows a friendly empty state when the user has no public collections" do
    get public_profile_url(users(:four).username)

    assert_response :success
    assert_select ".public-profile--empty"
  end

  test "404s for an unknown username" do
    get public_profile_url("does-not-exist")

    assert_response :not_found
  end

  test "shows a 'Redigera profil' link only to the profile's own owner" do
    sign_in_as(users(:one))

    get public_profile_url(users(:one).username)
    assert_select ".public-profile--edit-link"

    get public_profile_url(users(:two).username)
    assert_select ".public-profile--edit-link", false
  end

  test "does not show a 'Redigera profil' link to an anonymous visitor" do
    get public_profile_url(users(:one).username)

    assert_select ".public-profile--edit-link", false
  end

  test "nudges the owner toward making a collection public when their own profile is empty" do
    sign_in_as(users(:four))

    get public_profile_url(users(:four).username)

    assert_select ".public-profile--empty-link", "dina samlingar"
  end

  test "shows a generic empty message to a visitor, without the owner-only nudge" do
    get public_profile_url(users(:four).username)

    assert_select ".public-profile--empty", text: /Disa Dahlberg har inga publika samlingar än/
    assert_select ".public-profile--empty-link", false
  end
end
