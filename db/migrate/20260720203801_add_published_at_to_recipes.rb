class AddPublishedAtToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :published_at, :datetime
  end
end
