class FinalizeUsernameOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :username, false
    add_index :users, :username, unique: true
  end
end
