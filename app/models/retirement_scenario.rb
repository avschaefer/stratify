class RetirementScenario < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :target_date, presence: true
  validates :current_savings, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :monthly_contribution, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :target_amount, presence: true, numericality: { greater_than: 0 }
  validates :expected_return_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  def years_to_target
    return 0 if target_date.nil?
    (target_date.year - Date.today.year)
  end
  
  def projected_value
    return current_savings if years_to_target <= 0
    
    monthly_rate = expected_return_rate / 100.0 / 12.0
    months = years_to_target * 12
    
    future_value_of_savings = current_savings * (1 + monthly_rate)**months
    future_value_of_contributions = monthly_contribution * (((1 + monthly_rate)**months - 1) / monthly_rate)
    
    future_value_of_savings + future_value_of_contributions
  end
  
  def progress_percentage
    return 0 if target_amount.nil? || target_amount.zero?
    [projected_value / target_amount * 100, 100].min
  end
end

