class RenameTaxScenariosToTaxes < ActiveRecord::Migration[8.0]
  def up
    rename_table :tax_scenarios, :taxes
    
    # Update field names to match data model
    rename_column :taxes, :income, :gross_income_cents if column_exists?(:taxes, :income)
    rename_column :taxes, :deductions, :deductions_cents if column_exists?(:taxes, :deductions)
    rename_column :taxes, :taxable_income, :taxable_income_cents if column_exists?(:taxes, :taxable_income)
    rename_column :taxes, :tax_paid, :tax_paid_cents if column_exists?(:taxes, :tax_paid)
    rename_column :taxes, :refund, :refund_cents if column_exists?(:taxes, :refund)
    
    # Convert to bigint for cents
    change_column :taxes, :gross_income_cents, :bigint if column_exists?(:taxes, :gross_income_cents)
    change_column :taxes, :deductions_cents, :bigint if column_exists?(:taxes, :deductions_cents)
    change_column :taxes, :taxable_income_cents, :bigint if column_exists?(:taxes, :taxable_income_cents)
    change_column :taxes, :tax_paid_cents, :bigint if column_exists?(:taxes, :tax_paid_cents)
    change_column :taxes, :refund_cents, :bigint if column_exists?(:taxes, :refund_cents)
    
    add_column :taxes, :payment_period, :string if !column_exists?(:taxes, :payment_period)
  end
  
  def down
    rename_table :taxes, :tax_scenarios
    rename_column :tax_scenarios, :gross_income_cents, :income if column_exists?(:tax_scenarios, :gross_income_cents)
    rename_column :tax_scenarios, :deductions_cents, :deductions if column_exists?(:tax_scenarios, :deductions_cents)
    rename_column :tax_scenarios, :taxable_income_cents, :taxable_income if column_exists?(:tax_scenarios, :taxable_income_cents)
    rename_column :tax_scenarios, :tax_paid_cents, :tax_paid if column_exists?(:tax_scenarios, :tax_paid_cents)
    rename_column :tax_scenarios, :refund_cents, :refund if column_exists?(:tax_scenarios, :refund_cents)
    
    change_column :tax_scenarios, :income, :decimal, precision: 12, scale: 2 if column_exists?(:tax_scenarios, :income)
    change_column :tax_scenarios, :deductions, :decimal, precision: 12, scale: 2 if column_exists?(:tax_scenarios, :deductions)
    change_column :tax_scenarios, :taxable_income, :decimal, precision: 12, scale: 2 if column_exists?(:tax_scenarios, :taxable_income)
    change_column :tax_scenarios, :tax_paid, :decimal, precision: 12, scale: 2 if column_exists?(:tax_scenarios, :tax_paid)
    change_column :tax_scenarios, :refund, :decimal, precision: 12, scale: 2 if column_exists?(:tax_scenarios, :refund)
    
    remove_column :tax_scenarios, :payment_period if column_exists?(:tax_scenarios, :payment_period)
  end
end

