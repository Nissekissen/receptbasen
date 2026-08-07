class CreatePersonalRecipeNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_recipe_notes do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.text :content, null: false
      t.timestamps

      t.index [ :user_id, :recipe_id ], unique: true
    end
  end
end
