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
  create_table "accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "account_type", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "index"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

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

  create_table "balances", force: :cascade do |t|
    t.integer "account_id", null: false
    t.bigint "amount_cents"
    t.date "balance_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_balances_on_balanceable_type_and_account_id"
    t.index ["account_id"], name: "index_monthly_snapshots_on_snapshotable"
    t.index ["balance_date"], name: "index_balances_on_balance_date"
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "rating_net_promoter"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "holdings", force: :cascade do |t|
    t.integer "portfolio_id", null: false
    t.string "ticker", null: false
    t.string "name"
    t.decimal "shares", precision: 10, scale: 2
    t.bigint "cost_basis_cents"
    t.decimal "index_weight", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id"], name: "index_holdings_on_portfolio_id"
    t.index ["ticker"], name: "index_holdings_on_ticker"
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
    t.bigint "principal_cents"
    t.decimal "rate_apr", precision: 5, scale: 2, null: false
    t.decimal "term_years", precision: 5, scale: 2, null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_period", default: "monthly"
    t.string "compounding_period", default: "monthly"
    t.text "notes"
    t.date "start_date"
    t.date "end_date"
    t.decimal "rate_apy", precision: 5, scale: 2
    t.bigint "periodic_payment_cents"
    t.bigint "current_period"
    t.bigint "current_balance_cents"
    t.index ["user_id"], name: "index_loans_on_user_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "prices", force: :cascade do |t|
    t.integer "holding_id", null: false
    t.date "date", null: false
    t.integer "amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holding_id", "date"], name: "index_prices_on_holding_id_and_date"
    t.index ["holding_id"], name: "index_prices_on_holding_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "referred_user_id", null: false
    t.date "signup_date"
    t.string "referral_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referral_code"], name: "index_referrals_on_referral_code", unique: true
    t.index ["referred_user_id"], name: "index_referrals_on_referred_user_id"
    t.index ["user_id"], name: "index_referrals_on_user_id"
  end

  create_table "retirements", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "age_start"
    t.integer "age_retirement"
    t.bigint "age_end"
    t.decimal "rate_inflation", precision: 5, scale: 2
    t.decimal "rate_contribution_growth", precision: 5, scale: 2
    t.decimal "rate_low", precision: 5, scale: 2
    t.decimal "rate_mid", precision: 5, scale: 2
    t.decimal "rate_high", precision: 5, scale: 2
    t.decimal "allocation_low_pre", precision: 5, scale: 2
    t.decimal "allocation_mid_pre", precision: 5, scale: 2
    t.decimal "allocation_high_pre", precision: 5, scale: 2
    t.decimal "allocation_low_post", precision: 5, scale: 2
    t.decimal "allocation_mid_post", precision: 5, scale: 2
    t.decimal "allocation_high_post", precision: 5, scale: 2
    t.bigint "contribution_annual_cents"
    t.bigint "withdrawal_annual_pv_cents"
    t.decimal "withdrawal_rate_fv", precision: 5, scale: 2
    t.index ["user_id"], name: "index_retirements_on_user_id"
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

  create_table "settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "date_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "taxes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "year", null: false
    t.bigint "gross_income_cents"
    t.bigint "deductions_cents"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "taxable_income_cents"
    t.bigint "tax_paid_cents"
    t.bigint "refund_cents"
    t.string "payment_period"
    t.index ["user_id"], name: "index_taxes_on_user_id"
  end

  create_table "trades", force: :cascade do |t|
    t.integer "holding_id"
    t.date "trade_date", null: false
    t.bigint "shares_quantity"
    t.bigint "amount_cents"
    t.bigint "price_cents"
    t.integer "trade_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["holding_id", "trade_date"], name: "index_trades_on_holding_id_and_trade_date"
    t.index ["holding_id"], name: "index_trades_on_holding_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "currency", default: "USD"
    t.string "timezone", default: "America/New_York"
    t.string "date_format", default: "MM/DD/YYYY"
    t.string "referral_code"
    t.string "subscription_period", default: "monthly"
    t.integer "subscription_price_cents"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["referral_code"], name: "index_users_on_referral_code", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "balances", "accounts"
  add_foreign_key "expenses", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "holdings", "portfolios"
  add_foreign_key "insurance_policies", "users"
  add_foreign_key "loans", "users"
  add_foreign_key "portfolios", "users"
  add_foreign_key "prices", "holdings"
  add_foreign_key "referrals", "users"
  add_foreign_key "referrals", "users", column: "referred_user_id"
  add_foreign_key "retirements", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "users"
  add_foreign_key "taxes", "users"
  add_foreign_key "trades", "holdings"
end
