class AddSplitFieldsToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :quantity, :string
    add_column :ingredients, :unit, :string
    add_column :ingredients, :name, :string
  end
end
