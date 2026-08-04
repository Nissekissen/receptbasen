class AddGroupInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.string :token, null: false
      t.references :group, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
