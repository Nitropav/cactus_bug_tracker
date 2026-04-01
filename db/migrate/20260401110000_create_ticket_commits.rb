class CreateTicketCommits < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_commits do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.string :commit_sha
      t.string :pull_request_url
      t.string :repository_name
      t.text :notes

      t.timestamps
    end

    add_index :ticket_commits, [:ticket_id, :commit_sha], unique: true, where: "commit_sha IS NOT NULL"
  end
end
