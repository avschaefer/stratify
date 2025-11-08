class AddLoanCalculationFieldsToLoans < ActiveRecord::Migration[8.0]
  def change
    add_column :loans, :rate_type, :string, default: 'apr'
    add_column :loans, :payment_frequency, :string, default: 'monthly'
    add_column :loans, :compounding_period, :string, default: 'monthly'
    add_column :loans, :notes, :text
  end
end

