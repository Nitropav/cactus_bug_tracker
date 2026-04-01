class CreateUserEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :user_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.text :message, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :user_events, [:user_id, :created_at]
    add_index :user_events, :event_type
  end
end
