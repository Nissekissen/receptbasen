require "test_helper"

class RecipeNotesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post recipe_note_url(recipes(:pannkakor)), params: { content: "Testanteckning" }

    assert_redirected_to new_session_path
  end

  test "creates a note for the current user" do
    sign_in_as(users(:three))
    recipe = recipes(:pannkakor)

    assert_difference "PersonalRecipeNote.count", 1 do
      post recipe_note_url(recipe), params: { content: "Dubbla degen." }
    end

    note = PersonalRecipeNote.find_by(user: users(:three), recipe: recipe)
    assert_equal "Dubbla degen.", note.content
  end

  test "updates the existing note instead of creating a second one" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)

    assert_no_difference "PersonalRecipeNote.count" do
      post recipe_note_url(recipe), params: { content: "Uppdaterad anteckning." }
    end

    assert_equal "Uppdaterad anteckning.", personal_recipe_notes(:one).reload.content
  end

  test "does not let one user's note submission affect another user's note on the same recipe" do
    sign_in_as(users(:one))
    recipe = recipes(:pannkakor)

    post recipe_note_url(recipe), params: { content: "Alice sin anteckning." }

    assert_equal "Grädda på lite lägre värme.", personal_recipe_notes(:two).reload.content
  end

  test "responds with a turbo stream" do
    sign_in_as(users(:three))

    post recipe_note_url(recipes(:pannkakor)), params: { content: "Testanteckning" }, as: :turbo_stream

    assert_response :success
  end

  test "redirects to the recipe for an html request" do
    sign_in_as(users(:three))

    post recipe_note_url(recipes(:pannkakor)), params: { content: "Testanteckning" }

    assert_redirected_to recipes(:pannkakor)
  end

  test "404s for a private manual recipe the signed-in user can't see" do
    sign_in_as(users(:two))

    assert_no_difference "PersonalRecipeNote.count" do
      post recipe_note_url(recipes(:kottbullar)), params: { content: "Ska inte gå." }
    end

    assert_response :not_found
  end

  test "owner can note their own manual recipe" do
    sign_in_as(users(:one))
    recipe = recipes(:kottbullar)

    assert_difference "PersonalRecipeNote.count", 1 do
      post recipe_note_url(recipe), params: { content: "Mer salt nästa gång." }
    end
  end
end
