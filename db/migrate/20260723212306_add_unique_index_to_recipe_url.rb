class AddUniqueIndexToRecipeUrl < ActiveRecord::Migration[8.1]
  def change
    add_index :recipes, :source_url, unique: true
  end
end
