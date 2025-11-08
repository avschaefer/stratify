class AddActualTaxFieldsToTaxScenarios < ActiveRecord::Migration[8.0]
  def change
    add_column :tax_scenarios, :taxable_income, :decimal, precision: 12, scale: 2, null: false, default: 0.0
    add_column :tax_scenarios, :tax_paid, :decimal, precision: 12, scale: 2, null: false, default: 0.0
    add_column :tax_scenarios, :refund, :decimal, precision: 12, scale: 2, null: false, default: 0.0
  end
end

