class CreateSavedRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_recipes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :collection, null: false, foreign_key: { on_delete: :cascade }
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.text :note
      t.integer :rating

      t.timestamps
    end

    add_index :saved_recipes, [ :collection_id, :recipe_id ], unique: true
  end
end
