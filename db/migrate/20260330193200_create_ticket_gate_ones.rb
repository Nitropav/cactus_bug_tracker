class CreateTicketGateOnes < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_gate_ones do |t|
      t.references :ticket, null: false, foreign_key: true, index: { unique: true }
      t.text :problem_description
      t.text :reproduction_steps
      t.text :expected_behavior
      t.text :actual_behavior
      t.text :environment_context
      t.text :attachments_summary
      t.datetime :completed_at

      t.timestamps
    end
  end
end
