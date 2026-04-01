# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_01_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ticket_comments", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_ticket_comments_on_author_id"
    t.index ["ticket_id"], name: "index_ticket_comments_on_ticket_id"
  end

  create_table "ticket_commits", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "author_id"
    t.string "commit_sha"
    t.string "pull_request_url"
    t.string "repository_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_ticket_commits_on_author_id"
    t.index ["ticket_id", "commit_sha"], name: "index_ticket_commits_on_ticket_id_and_commit_sha", unique: true, where: "(commit_sha IS NOT NULL)"
    t.index ["ticket_id"], name: "index_ticket_commits_on_ticket_id"
  end

  create_table "ticket_events", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "actor_id"
    t.string "event_type", null: false
    t.text "message", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_ticket_events_on_actor_id"
    t.index ["event_type"], name: "index_ticket_events_on_event_type"
    t.index ["ticket_id"], name: "index_ticket_events_on_ticket_id"
  end

  create_table "ticket_gate_ones", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.text "problem_description"
    t.text "reproduction_steps"
    t.text "expected_behavior"
    t.text "actual_behavior"
    t.text "environment_context"
    t.text "attachments_summary"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_ticket_gate_ones_on_ticket_id", unique: true
  end

  create_table "ticket_gate_twos", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.text "root_cause"
    t.text "fix_summary"
    t.text "verification_steps"
    t.string "primary_commit_sha"
    t.string "primary_pull_request_url"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_ticket_gate_twos_on_ticket_id", unique: true
  end

  create_table "tickets", force: :cascade do |t|
    t.string "title", null: false
    t.text "summary"
    t.integer "status", default: 0, null: false
    t.integer "severity", default: 1, null: false
    t.string "domain", default: "unknown", null: false
    t.string "external_reference"
    t.datetime "resolved_at"
    t.datetime "closed_at"
    t.bigint "reported_by_id", null: false
    t.bigint "assigned_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_tickets_on_assigned_to_id"
    t.index ["domain"], name: "index_tickets_on_domain"
    t.index ["reported_by_id"], name: "index_tickets_on_reported_by_id"
    t.index ["severity"], name: "index_tickets_on_severity"
    t.index ["status"], name: "index_tickets_on_status"
  end

  create_table "training_examples", force: :cascade do |t|
    t.bigint "ticket_id", null: false
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.text "problem_description"
    t.text "reproduction_steps"
    t.text "expected_behavior"
    t.text "actual_behavior"
    t.text "environment_context"
    t.text "root_cause"
    t.text "fix_summary"
    t.text "verification_steps"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "generated_at"
    t.datetime "reviewed_at"
    t.datetime "exported_at"
    t.text "review_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewed_by_id"], name: "index_training_examples_on_reviewed_by_id"
    t.index ["status"], name: "index_training_examples_on_status"
    t.index ["ticket_id", "status"], name: "index_training_examples_on_ticket_pending_review", unique: true, where: "(status = 0)"
    t.index ["ticket_id"], name: "index_training_examples_on_ticket_id"
  end

  create_table "user_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "actor_id"
    t.string "event_type", null: false
    t.text "message", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_user_events_on_actor_id"
    t.index ["event_type"], name: "index_user_events_on_event_type"
    t.index ["user_id", "created_at"], name: "index_user_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_user_events_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.string "password_digest", null: false
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.datetime "deactivated_at"
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "ticket_comments", "tickets"
  add_foreign_key "ticket_comments", "users", column: "author_id"
  add_foreign_key "ticket_commits", "tickets"
  add_foreign_key "ticket_commits", "users", column: "author_id"
  add_foreign_key "ticket_events", "tickets"
  add_foreign_key "ticket_events", "users", column: "actor_id"
  add_foreign_key "ticket_gate_ones", "tickets"
  add_foreign_key "ticket_gate_twos", "tickets"
  add_foreign_key "tickets", "users", column: "assigned_to_id"
  add_foreign_key "tickets", "users", column: "reported_by_id"
  add_foreign_key "training_examples", "tickets"
  add_foreign_key "training_examples", "users", column: "reviewed_by_id"
  add_foreign_key "user_events", "users"
  add_foreign_key "user_events", "users", column: "actor_id"
end
