class CreateCollectionCollaborators < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_collaborators do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :collection, null: false, foreign_key: { on_delete: :cascade }
      t.integer :role, default: 0, null: false
      t.timestamps

      t.index [ :user_id, :collection_id ], unique: true
    end
  end
end
