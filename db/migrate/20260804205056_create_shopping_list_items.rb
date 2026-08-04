class CreateShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :content, null: false
      t.boolean :checked, null: false, default: false
      t.references :recipe, foreign_key: true
      t.timestamps
    end
  end
end
