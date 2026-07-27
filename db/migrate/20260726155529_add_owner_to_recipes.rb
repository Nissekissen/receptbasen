class AddOwnerToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_reference :recipes, :owner, null: true, foreign_key: { to_table: :users, on_delete: :cascade }

    # Manual recipes have no source URL. The existing unique index on source_url
    # is untouched — Postgres and SQLite both allow multiple NULLs under a unique
    # index, so several manual recipes can coexist without conflict.
    change_column_null :recipes, :source_url, true
  end
end
