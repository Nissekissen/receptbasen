class RemoveGroupFromCollections < ActiveRecord::Migration[8.1]
  def change
    remove_reference :collections, :group, foreign_key: true
  end
end
