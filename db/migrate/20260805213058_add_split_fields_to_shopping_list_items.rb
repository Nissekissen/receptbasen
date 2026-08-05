class AddSplitFieldsToShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    add_column :shopping_list_items, :quantity, :string
    add_column :shopping_list_items, :unit, :string
    add_column :shopping_list_items, :name, :string
  end
end
