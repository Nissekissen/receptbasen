class AddLockedToCollections < ActiveRecord::Migration[8.1]
  def change
    add_column :collections, :locked, :boolean, null: false, default: false
  end
end
