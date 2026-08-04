require "test_helper"

class ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get shopping_list_items_url

    assert_redirected_to new_session_path
  end

  test "lists only the current user's items" do
    sign_in_as(users(:one))

    get shopping_list_items_url

    assert_response :success
    assert_select ".shopping-list--content", text: "Mjölk"
    assert_select ".shopping-list--content", text: "Bröd", count: 0
  end

  test "creates a manual item" do
    sign_in_as(users(:one))

    assert_difference "ShoppingListItem.count", 1 do
      post shopping_list_items_url, params: { content: "Ägg" }
    end

    assert_nil ShoppingListItem.last.recipe
    assert_redirected_to shopping_list_items_path
  end

  test "does not create a blank item" do
    sign_in_as(users(:one))

    assert_no_difference "ShoppingListItem.count" do
      post shopping_list_items_url, params: { content: "" }
    end
  end

  test "checks off an item" do
    sign_in_as(users(:one))

    patch shopping_list_item_url(shopping_list_items(:one_milk)), params: { checked: "true" }

    assert_response :no_content
    assert shopping_list_items(:one_milk).reload.checked?
  end

  test "unchecks an item" do
    sign_in_as(users(:one))
    shopping_list_items(:one_milk).update!(checked: true)

    patch shopping_list_item_url(shopping_list_items(:one_milk)), params: { checked: "false" }

    assert_not shopping_list_items(:one_milk).reload.checked?
  end

  test "404s toggling another user's item" do
    sign_in_as(users(:one))

    patch shopping_list_item_url(shopping_list_items(:two_bread)), params: { checked: "true" }

    assert_response :not_found
    assert_not shopping_list_items(:two_bread).reload.checked?
  end

  test "removes an item" do
    sign_in_as(users(:one))

    assert_difference "ShoppingListItem.count", -1 do
      delete shopping_list_item_url(shopping_list_items(:one_milk))
    end
  end

  test "404s removing another user's item" do
    sign_in_as(users(:one))

    assert_no_difference "ShoppingListItem.count" do
      delete shopping_list_item_url(shopping_list_items(:two_bread))
    end

    assert_response :not_found
  end

  test "clears only the current user's items" do
    sign_in_as(users(:one))
    milk_id = shopping_list_items(:one_milk).id
    bread_id = shopping_list_items(:two_bread).id

    assert_difference "ShoppingListItem.count", -1 do
      delete destroy_all_shopping_list_items_url
    end

    assert_not ShoppingListItem.exists?(milk_id)
    assert ShoppingListItem.exists?(bread_id)
    assert_redirected_to shopping_list_items_path
  end
end
