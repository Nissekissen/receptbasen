class NormalizeBlankRecipeTimes < ActiveRecord::Migration[8.1]
  # Scoped to the table name rather than the real Recipe model — a migration has
  # to stay correct even if Recipe changes in unrelated ways later.
  class MigrationRecipe < ActiveRecord::Base
    self.table_name = "recipes"
  end

  def up
    MigrationRecipe.where(prep_time: "").update_all(prep_time: nil)
    MigrationRecipe.where(cook_time: "").update_all(cook_time: nil)
    MigrationRecipe.where(total_time: "").update_all(total_time: nil)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
