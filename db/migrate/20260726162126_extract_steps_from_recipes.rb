class ExtractStepsFromRecipes < ActiveRecord::Migration[8.1]
  # Scoped to the table name rather than using the real Recipe/Step models —
  # a migration has to stay correct even after those models change in ways
  # unrelated to this migration.
  class MigrationRecipe < ActiveRecord::Base
    self.table_name = "recipes"
  end

  class MigrationStep < ActiveRecord::Base
    self.table_name = "steps"
  end

  def up
    create_table :steps do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.string :content, null: false
      t.integer :position, null: false

      t.timestamps
    end
    add_index :steps, [ :recipe_id, :position ], unique: true

    MigrationRecipe.reset_column_information

    # Read everything into memory BEFORE removing the column. SQLite has no native
    # DROP COLUMN — remove_column rebuilds the whole `recipes` table (copy to a temp
    # table, DROP TABLE recipes, recreate, copy back), and that intermediate DROP
    # cascades through steps.recipe_id's ON DELETE CASCADE if any `steps` rows
    # already exist at that point, silently wiping out everything just inserted.
    steps_by_recipe_id = MigrationRecipe.pluck(:id, :steps).to_h

    remove_column :recipes, :steps

    MigrationStep.reset_column_information

    steps_by_recipe_id.each do |recipe_id, steps|
      Array(steps).each_with_index do |content, index|
        MigrationStep.create!(recipe_id: recipe_id, content: content, position: index)
      end
    end
  end

  def down
    add_column :recipes, :steps, :json

    MigrationRecipe.reset_column_information
    MigrationStep.reset_column_information

    MigrationStep.order(:position).group_by(&:recipe_id).each do |recipe_id, steps|
      MigrationRecipe.find(recipe_id).update!(steps: steps.map(&:content))
    end

    drop_table :steps
  end
end
