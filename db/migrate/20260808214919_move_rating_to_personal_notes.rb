class MoveRatingToPersonalNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_recipe_notes, :rating, :integer
    change_column_null :personal_recipe_notes, :content, true
    remove_column :saved_recipes, :rating, :integer
  end
end
