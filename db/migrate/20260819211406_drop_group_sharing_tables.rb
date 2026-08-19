class DropGroupSharingTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :invites
    drop_table :memberships
    drop_table :groups
  end
end
