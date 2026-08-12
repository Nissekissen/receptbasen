class AddQuantityValueToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :quantity_value, :float
  end
end
