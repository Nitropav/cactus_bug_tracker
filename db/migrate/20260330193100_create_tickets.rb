class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :summary
      t.integer :status, null: false, default: 0
      t.integer :severity, null: false, default: 1
      t.string :domain, null: false, default: "unknown"
      t.string :external_reference
      t.datetime :resolved_at
      t.datetime :closed_at
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :severity
    add_index :tickets, :domain
  end
end
