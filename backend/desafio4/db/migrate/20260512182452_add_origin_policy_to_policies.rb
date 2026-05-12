class AddOriginPolicyToPolicies < ActiveRecord::Migration[8.1]
  def change
    add_reference :policies, :origin_policy, foreign_key: { to_table: :policies }, null: true, index: true
  end
end
