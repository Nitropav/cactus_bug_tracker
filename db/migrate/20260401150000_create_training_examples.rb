class CreateTrainingExamples < ActiveRecord::Migration[8.0]
  def change
    create_table :training_examples do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.string :title, null: false
      t.text :problem_description
      t.text :reproduction_steps
      t.text :expected_behavior
      t.text :actual_behavior
      t.text :environment_context
      t.text :root_cause
      t.text :fix_summary
      t.text :verification_steps
      t.jsonb :metadata, null: false, default: {}
      t.datetime :generated_at
      t.datetime :reviewed_at
      t.datetime :exported_at
      t.text :review_notes

      t.timestamps
    end

    add_index :training_examples, :status
    add_index :training_examples, [:ticket_id, :status],
              unique: true,
              where: "status = 0",
              name: "index_training_examples_on_ticket_pending_review"
  end
end
