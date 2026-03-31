class CreateTicketGateTwos < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_gate_twos do |t|
      t.references :ticket, null: false, foreign_key: true, index: { unique: true }
      t.text :root_cause
      t.text :fix_summary
      t.text :verification_steps
      t.string :primary_commit_sha
      t.string :primary_pull_request_url
      t.datetime :completed_at

      t.timestamps
    end
  end
end
