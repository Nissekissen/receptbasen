class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :taggings, [ :recipe_id, :tag_id ], unique: true
  end
end
