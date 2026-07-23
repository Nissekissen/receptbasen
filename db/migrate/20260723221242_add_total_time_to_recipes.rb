class AddTotalTimeToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :total_time, :string
  end
end
