class CreatePolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :policies do |t|
      t.string  :policy_number, null: false
      t.string  :insured, null: false
      t.string  :policy_holder, null: false
      t.string  :beneficiary, null: false
      t.date    :coverage_start_date, null: false
      t.date    :coverage_end_date, null: false
      t.date    :issue_date, null: false
      t.string  :policy_type, null: false
      t.decimal :insured_amount, precision: 15, scale: 2, null: false
      t.decimal :lmg, precision: 15, scale: 2, null: false

      t.timestamps
    end
    add_index :policies, :policy_number, unique: true
    add_index :policies, :policy_holder
  end
end
