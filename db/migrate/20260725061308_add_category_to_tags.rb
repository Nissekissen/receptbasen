class AddCategoryToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :category, :integer, null: false
  end
end
