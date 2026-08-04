class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :admin, null: false, default: false

      t.timestamps
    end

    add_index :memberships, [ :group_id, :user_id ], unique: true
  end
end
