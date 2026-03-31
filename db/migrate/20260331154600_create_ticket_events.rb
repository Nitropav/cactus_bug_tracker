class CreateTicketEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_events do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.text :message, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :ticket_events, :event_type
  end
end
