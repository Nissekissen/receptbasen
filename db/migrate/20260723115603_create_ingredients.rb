class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :content
      t.references :recipe, null: false, foreign_key: true

      t.timestamps
    end
  end
end
