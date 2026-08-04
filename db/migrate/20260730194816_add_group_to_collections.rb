class AddGroupToCollections < ActiveRecord::Migration[8.1]
  def change
    add_reference :collections, :group, null: true, foreign_key: { on_delete: :cascade }
  end
end
