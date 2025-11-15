class RenameRetirementScenariosToRetirements < ActiveRecord::Migration[8.0]
  def up
    rename_table :retirement_scenarios, :retirements
    
    # Remove old fields and add new ones from data model
    remove_column :retirements, :target_date if column_exists?(:retirements, :target_date)
    remove_column :retirements, :current_savings if column_exists?(:retirements, :current_savings)
    remove_column :retirements, :monthly_contribution if column_exists?(:retirements, :monthly_contribution)
    remove_column :retirements, :target_amount if column_exists?(:retirements, :target_amount)
    remove_column :retirements, :expected_return_rate if column_exists?(:retirements, :expected_return_rate)
    remove_column :retirements, :risk_level if column_exists?(:retirements, :risk_level)
    
    # Add new fields from data model
    add_column :retirements, :age_start, :integer
    add_column :retirements, :age_retirement, :integer
    add_column :retirements, :age_end, :bigint
    add_column :retirements, :rate_inflation, :decimal, precision: 5, scale: 2
    add_column :retirements, :rate_contribution_growth, :decimal, precision: 5, scale: 2
    add_column :retirements, :rate_low, :decimal, precision: 5, scale: 2
    add_column :retirements, :rate_mid, :decimal, precision: 5, scale: 2
    add_column :retirements, :rate_high, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_low_pre, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_mid_pre, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_high_pre, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_low_post, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_mid_post, :decimal, precision: 5, scale: 2
    add_column :retirements, :allocation_high_post, :decimal, precision: 5, scale: 2
    add_column :retirements, :contribution_annual_cents, :bigint
    add_column :retirements, :withdrawal_annual_pv_cents, :bigint
    add_column :retirements, :withdrawal_rate_fv, :decimal, precision: 5, scale: 2
  end
  
  def down
    rename_table :retirements, :retirement_scenarios
    
    add_column :retirement_scenarios, :target_date, :date
    add_column :retirement_scenarios, :current_savings, :decimal, precision: 12, scale: 2, default: 0.0
    add_column :retirement_scenarios, :monthly_contribution, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :retirement_scenarios, :target_amount, :decimal, precision: 12, scale: 2
    add_column :retirement_scenarios, :expected_return_rate, :decimal, precision: 5, scale: 2
    add_column :retirement_scenarios, :risk_level, :string
    
    remove_column :retirement_scenarios, :age_start if column_exists?(:retirement_scenarios, :age_start)
    remove_column :retirement_scenarios, :age_retirement if column_exists?(:retirement_scenarios, :age_retirement)
    remove_column :retirement_scenarios, :age_end if column_exists?(:retirement_scenarios, :age_end)
    remove_column :retirement_scenarios, :rate_inflation if column_exists?(:retirement_scenarios, :rate_inflation)
    remove_column :retirement_scenarios, :rate_contribution_growth if column_exists?(:retirement_scenarios, :rate_contribution_growth)
    remove_column :retirement_scenarios, :rate_low if column_exists?(:retirement_scenarios, :rate_low)
    remove_column :retirement_scenarios, :rate_mid if column_exists?(:retirement_scenarios, :rate_mid)
    remove_column :retirement_scenarios, :rate_high if column_exists?(:retirement_scenarios, :rate_high)
    remove_column :retirement_scenarios, :allocation_low_pre if column_exists?(:retirement_scenarios, :allocation_low_pre)
    remove_column :retirement_scenarios, :allocation_mid_pre if column_exists?(:retirement_scenarios, :allocation_mid_pre)
    remove_column :retirement_scenarios, :allocation_high_pre if column_exists?(:retirement_scenarios, :allocation_high_pre)
    remove_column :retirement_scenarios, :allocation_low_post if column_exists?(:retirement_scenarios, :allocation_low_post)
    remove_column :retirement_scenarios, :allocation_mid_post if column_exists?(:retirement_scenarios, :allocation_mid_post)
    remove_column :retirement_scenarios, :allocation_high_post if column_exists?(:retirement_scenarios, :allocation_high_post)
    remove_column :retirement_scenarios, :contribution_annual_cents if column_exists?(:retirement_scenarios, :contribution_annual_cents)
    remove_column :retirement_scenarios, :withdrawal_annual_pv_cents if column_exists?(:retirement_scenarios, :withdrawal_annual_pv_cents)
    remove_column :retirement_scenarios, :withdrawal_rate_fv if column_exists?(:retirement_scenarios, :withdrawal_rate_fv)
  end
end

