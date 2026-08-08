class CreateCookLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :cook_logs do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps

      t.index [ :user_id, :created_at ]
    end
  end
end
