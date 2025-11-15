class Retirement < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :age_start, presence: true, numericality: { only_integer: true }
  validates :age_retirement, presence: true, numericality: { only_integer: true }
  validates :age_end, presence: true, numericality: { only_integer: true }
  validates :rate_inflation, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_contribution_growth, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_low, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_mid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_high, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :contribution_annual_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  def contribution_annual
    contribution_annual_cents / 100.0 if contribution_annual_cents
  end
  
  def contribution_annual=(value)
    self.contribution_annual_cents = (value.to_f * 100).round if value
  end
  
  def withdrawal_annual_pv
    withdrawal_annual_pv_cents / 100.0 if withdrawal_annual_pv_cents
  end
  
  def withdrawal_annual_pv=(value)
    self.withdrawal_annual_pv_cents = (value.to_f * 100).round if value
  end
  
  def years_to_target
    return 0 if age_retirement.nil? || age_start.nil?
    age_retirement - age_start
  end
  
  def years_in_retirement
    return 0 if age_end.nil? || age_retirement.nil?
    age_end - age_retirement
  end
  
  def projected_value(rate = nil)
    return 0 if years_to_target <= 0
    
    rate ||= rate_mid
    monthly_rate = rate / 100.0 / 12.0
    months = years_to_target * 12
    
    # Future value of current savings (assuming 0 for now)
    future_value_of_savings = 0
    
    # Future value of annual contributions
    monthly_contribution = contribution_annual / 12.0
    future_value_of_contributions = monthly_contribution * (((1 + monthly_rate)**months - 1) / monthly_rate)
    
    future_value_of_savings + future_value_of_contributions
  end
  
  def progress_percentage(target_amount_cents = nil)
    return 0 if target_amount_cents.nil? || target_amount_cents.zero?
    projected = projected_value * 100  # Convert to cents
    [projected / target_amount_cents * 100, 100].min
  end
  
  # Compatibility methods for RetirementProjectionService
  def current_savings
    0  # Not tracked in new model - would need to be calculated from accounts
  end
  
  def target_amount
    # Calculate target based on withdrawal needs
    return 0 if withdrawal_annual_pv_cents.nil? || withdrawal_rate_fv.nil?
    (withdrawal_annual_pv_cents / 100.0) / (withdrawal_rate_fv / 100.0)
  end
  
  def monthly_contribution
    return 0 if contribution_annual_cents.nil?
    contribution_annual / 12.0
  end
  
  def expected_return_rate
    rate_mid || 7.0
  end
  
  def target_date
    return nil if age_retirement.nil? || age_start.nil?
    Date.today + (age_retirement - age_start).years
  end
end

