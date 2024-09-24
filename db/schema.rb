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

ActiveRecord::Schema[8.1].define(version: 2026_09_22_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_digest", null: false
    t.string "key_prefix", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.uuid "project_id", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["key_prefix"], name: "index_api_keys_on_key_prefix"
    t.index ["project_id"], name: "index_api_keys_on_project_id"
  end

  create_table "deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.datetime "next_attempt_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "webhook_endpoint_id", null: false
    t.index ["event_id", "webhook_endpoint_id"], name: "index_deliveries_on_event_id_and_webhook_endpoint_id", unique: true
    t.index ["event_id"], name: "index_deliveries_on_event_id"
    t.index ["next_attempt_at"], name: "index_deliveries_on_next_attempt_at"
    t.index ["status"], name: "index_deliveries_on_status"
    t.index ["webhook_endpoint_id", "created_at"], name: "index_deliveries_on_webhook_endpoint_id_and_created_at"
    t.index ["webhook_endpoint_id"], name: "index_deliveries_on_webhook_endpoint_id"
  end

  create_table "delivery_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempt_number", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.uuid "delivery_id", null: false
    t.integer "duration_ms"
    t.string "error_message"
    t.integer "http_status"
    t.text "response_body"
    t.jsonb "response_headers", default: {}
    t.datetime "started_at"
    t.boolean "success", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id", "attempt_number"], name: "index_delivery_attempts_on_delivery_id_and_attempt_number"
    t.index ["delivery_id"], name: "index_delivery_attempts_on_delivery_id"
  end

  create_table "endpoint_event_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_type_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "webhook_endpoint_id", null: false
    t.index ["event_type_id"], name: "index_endpoint_event_types_on_event_type_id"
    t.index ["webhook_endpoint_id", "event_type_id"], name: "idx_endpoint_event_types_unique", unique: true
    t.index ["webhook_endpoint_id"], name: "index_endpoint_event_types_on_webhook_endpoint_id"
  end

  create_table "event_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.uuid "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_event_types_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_event_types_on_project_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.uuid "project_id", null: false
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_events_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_events_on_project_id"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "organization_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_projects_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_endpoints", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: true, null: false
    t.string "name", null: false
    t.datetime "previous_secret_expires_at"
    t.string "previous_signing_secret"
    t.uuid "project_id", null: false
    t.string "signing_secret", null: false
    t.string "signing_secret_prefix", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["project_id"], name: "index_webhook_endpoints_on_project_id"
  end

  add_foreign_key "api_keys", "projects"
  add_foreign_key "deliveries", "events"
  add_foreign_key "deliveries", "webhook_endpoints"
  add_foreign_key "delivery_attempts", "deliveries"
  add_foreign_key "endpoint_event_types", "event_types"
  add_foreign_key "endpoint_event_types", "webhook_endpoints"
  add_foreign_key "event_types", "projects"
  add_foreign_key "events", "projects"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "projects", "organizations"
  add_foreign_key "webhook_endpoints", "projects"
end
