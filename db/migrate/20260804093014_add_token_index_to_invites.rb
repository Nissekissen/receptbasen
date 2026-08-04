class AddTokenIndexToInvites < ActiveRecord::Migration[8.1]
  def change
    add_index :invites, :token, unique: true
  end
end
