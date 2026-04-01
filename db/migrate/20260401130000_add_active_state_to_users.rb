class AddActiveStateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :active, :boolean, default: true, null: false
    add_column :users, :deactivated_at, :datetime

    add_index :users, :active
  end
end
