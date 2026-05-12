
ActiveRecord::Schema[8.1].define(version: 2026_05_12_182452) do
  enable_extension "pg_catalog.plpgsql"

  create_table "policies", force: :cascade do |t|
    t.string "beneficiary", null: false
    t.date "coverage_end_date", null: false
    t.date "coverage_start_date", null: false
    t.datetime "created_at", null: false
    t.string "insured", null: false
    t.decimal "insured_amount", precision: 15, scale: 2, null: false
    t.date "issue_date", null: false
    t.decimal "lmg", precision: 15, scale: 2, null: false
    t.bigint "origin_policy_id"
    t.string "policy_holder", null: false
    t.string "policy_number", null: false
    t.string "policy_type", null: false
    t.datetime "updated_at", null: false
    t.index ["origin_policy_id"], name: "index_policies_on_origin_policy_id"
    t.index ["policy_holder"], name: "index_policies_on_policy_holder"
    t.index ["policy_number"], name: "index_policies_on_policy_number", unique: true
  end

  add_foreign_key "policies", "policies", column: "origin_policy_id"
end
