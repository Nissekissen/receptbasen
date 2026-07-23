class AddCascadeToIngredientsRecipeForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :ingredients, :recipes
    add_foreign_key :ingredients, :recipes, on_delete: :cascade
  end
end
