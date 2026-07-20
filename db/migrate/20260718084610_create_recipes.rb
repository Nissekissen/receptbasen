class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :source_url, null: false
      t.integer :status, null: false, default: 0
      t.string :title
      t.string :source_domain
      t.string :description
      t.string :image_url
      t.string :prep_time
      t.string :cook_time
      t.string :servings

      t.timestamps
    end
  end
end
