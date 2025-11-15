class UpdateLoansStructure < ActiveRecord::Migration[8.0]
  def change
    # Rename and convert fields to match data model
    rename_column :loans, :principal, :principal_cents if column_exists?(:loans, :principal)
    rename_column :loans, :interest_rate, :rate_apr if column_exists?(:loans, :interest_rate)
    
    # Convert principal to bigint cents
    change_column :loans, :principal_cents, :bigint if column_exists?(:loans, :principal_cents)
    
    # Add new fields
    add_column :loans, :start_date, :date if !column_exists?(:loans, :start_date)
    add_column :loans, :end_date, :date if !column_exists?(:loans, :end_date)
    add_column :loans, :rate_apy, :decimal, precision: 5, scale: 2 if !column_exists?(:loans, :rate_apy)
    rename_column :loans, :payment_frequency, :payment_period if column_exists?(:loans, :payment_frequency)
    rename_column :loans, :compounding_period, :compounding_period if column_exists?(:loans, :compounding_period)
    add_column :loans, :periodic_payment_cents, :bigint if !column_exists?(:loans, :periodic_payment_cents)
    add_column :loans, :current_period, :bigint if !column_exists?(:loans, :current_period)
    add_column :loans, :current_balance_cents, :bigint if !column_exists?(:loans, :current_balance_cents)
    
    # Remove old rate_type field if it exists (replaced by rate_apr and rate_apy)
    remove_column :loans, :rate_type if column_exists?(:loans, :rate_type)
  end
end

