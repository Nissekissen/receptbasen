require "application_system_test_case"

class CookModeTest < ApplicationSystemTestCase
  test "stepping through cook mode and marking a recipe as cooked logs a cook" do
    recipe = recipes(:pannkakor)
    recipe.steps.create!(content: "Vispa ihop mjöl, mjölk och ägg till en smet.", position: 0)
    recipe.steps.create!(content: "Stek pannkakorna i smör, ca 2 minuter per sida.", position: 1)
    recipe.steps.create!(content: "Servera med sylt och grädde.", position: 2)
    recipe.ingredients.create!(content: "4 dl mjölk", quantity: "4", unit: "dl", name: "mjölk")

    visit login_path
    fill_in "E-postadress", with: users(:one).email_address
    fill_in "Lösenord", with: "password"
    click_button "Logga in"
    assert_text users(:one).name

    visit recipe_path(recipe)
    click_on "Laga nu"

    assert_text(/steg 1 av 3/i)
    assert_text "Vispa ihop mjöl, mjölk och ägg till en smet."
    assert_text "02. Stek pannkakorna i smör, ca 2 minuter per sida."

    click_on "Nästa steg"
    assert_text(/steg 2 av 3/i)
    assert_text "Stek pannkakorna i smör, ca 2 minuter per sida."
    assert_text "2:00"

    click_on "Nästa steg"
    assert_text(/steg 3 av 3/i)
    assert_text "Servera med sylt och grädde."
    assert_no_button "Nästa steg"

    assert_difference -> { recipe.cook_logs.count }, 1 do
      click_on "Markera som lagad"
      assert_current_path recipe_path(recipe)
    end

    assert_equal users(:one), recipe.cook_logs.last.user
  end

  test "föregående exits cook mode on the first step and steps backward afterwards" do
    recipe = recipes(:pannkakor)
    recipe.steps.create!(content: "Vispa ihop mjöl, mjölk och ägg till en smet.", position: 0)
    recipe.steps.create!(content: "Stek pannkakorna i smör, ca 2 minuter per sida.", position: 1)

    visit login_path
    fill_in "E-postadress", with: users(:one).email_address
    fill_in "Lösenord", with: "password"
    click_button "Logga in"
    assert_text users(:one).name

    visit recipe_path(recipe)
    click_on "Laga nu"

    assert_text(/steg 1 av 2/i)
    click_on "Stäng"
    assert_current_path recipe_path(recipe)

    visit cook_recipe_path(recipe)
    click_on "Nästa steg"
    assert_text(/steg 2 av 2/i)

    click_on "Föregående"
    assert_text(/steg 1 av 2/i)
  end
end
