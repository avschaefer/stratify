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

ActiveRecord::Schema[8.0].define(version: 2025_11_05_232241) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "insurance_policies", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "policy_type", null: false
    t.string "provider", null: false
    t.decimal "coverage_amount", precision: 12, scale: 2, null: false
    t.decimal "premium", precision: 10, scale: 2, null: false
    t.decimal "term_years", precision: 5, scale: 2, null: false
    t.integer "status", default: 0
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_insurance_policies_on_user_id"
  end

  create_table "loans", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.decimal "principal", precision: 10, scale: 2, null: false
    t.decimal "interest_rate", precision: 5, scale: 2, null: false
    t.decimal "term_years", precision: 5, scale: 2, null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rate_type", default: "apr"
    t.string "payment_frequency", default: "monthly"
    t.string "compounding_period", default: "monthly"
    t.text "notes"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "monthly_snapshots", force: :cascade do |t|
    t.string "snapshotable_type", null: false
    t.integer "snapshotable_id", null: false
    t.decimal "balance", precision: 10, scale: 2, null: false
    t.date "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_monthly_snapshots_on_recorded_at"
    t.index ["snapshotable_type", "snapshotable_id"], name: "idx_on_snapshotable_type_snapshotable_id_36196ad6c9"
    t.index ["snapshotable_type", "snapshotable_id"], name: "index_monthly_snapshots_on_snapshotable"
  end

  create_table "portfolios", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "asset_type", null: false
    t.string "ticker", null: false
    t.date "purchase_date", null: false
    t.decimal "purchase_price", precision: 10, scale: 2, null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "retirement_scenarios", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.date "target_date", null: false
    t.decimal "current_savings", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "monthly_contribution", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "target_amount", precision: 12, scale: 2, null: false
    t.decimal "expected_return_rate", precision: 5, scale: 2, null: false
    t.string "risk_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_retirement_scenarios_on_user_id"
  end

  create_table "savings_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "account_type", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_savings_accounts_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tax_scenarios", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "year", null: false
    t.decimal "income", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "deductions", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "taxable_income", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "refund", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["user_id"], name: "index_tax_scenarios_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "currency", default: "USD"
    t.string "timezone", default: "America/New_York"
    t.string "date_format", default: "MM/DD/YYYY"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "expenses", "users"
  add_foreign_key "insurance_policies", "users"
  add_foreign_key "loans", "users"
  add_foreign_key "portfolios", "users"
  add_foreign_key "retirement_scenarios", "users"
  add_foreign_key "savings_accounts", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tax_scenarios", "users"
end
