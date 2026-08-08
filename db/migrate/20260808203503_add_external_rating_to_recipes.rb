class AddExternalRatingToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :external_rating, :float
    add_column :recipes, :external_rating_count, :integer
  end
end
