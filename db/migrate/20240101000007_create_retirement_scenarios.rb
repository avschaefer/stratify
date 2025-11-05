class CreateRetirementScenarios < ActiveRecord::Migration[7.1]
  def change
    create_table :retirement_scenarios do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :target_date, null: false
      t.decimal :current_savings, precision: 12, scale: 2, null: false, default: 0
      t.decimal :monthly_contribution, precision: 10, scale: 2, null: false, default: 0
      t.decimal :target_amount, precision: 12, scale: 2, null: false
      t.decimal :expected_return_rate, precision: 5, scale: 2, null: false
      t.string :risk_level

      t.timestamps
    end
  end
end

