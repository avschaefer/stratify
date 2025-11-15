class Loan < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :principal_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :rate_apr, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_years, presence: true, numericality: { greater_than: 0 }
  
  enum :status, { draft: 0, active: 1 }, prefix: :loan_status
  enum :payment_period, { monthly: 'monthly', biweekly: 'biweekly', weekly: 'weekly', yearly: 'yearly' }, default: 'monthly', prefix: :payment
  enum :compounding_period, { monthly: 'monthly', daily: 'daily', yearly: 'yearly' }, default: 'monthly', prefix: :compounding
  
  def principal
    principal_cents / 100.0 if principal_cents
  end
  
  def principal=(value)
    self.principal_cents = (value.to_f * 100).round if value
  end
  
  def periodic_payment
    periodic_payment_cents / 100.0 if periodic_payment_cents
  end
  
  def periodic_payment=(value)
    self.periodic_payment_cents = (value.to_f * 100).round if value
  end
  
  def current_balance
    current_balance_cents / 100.0 if current_balance_cents
  end
  
  def current_balance=(value)
    self.current_balance_cents = (value.to_f * 100).round if value
  end
  
  def monthly_payment
    return 0 if principal_cents.nil? || rate_apr.nil? || term_years.nil?
    
    monthly_rate = rate_apr / 100.0 / 12.0
    months = term_years * 12
    
    if monthly_rate == 0
      principal / months
    else
      principal * (monthly_rate * (1 + monthly_rate)**months) / ((1 + monthly_rate)**months - 1)
    end
  end
  
  def total_interest
    (monthly_payment * term_years * 12) - principal
  end
  
  def total_amount
    monthly_payment * term_years * 12
  end

  # Progress tracking methods
  def principal_paid
    return 0 if principal_cents.nil?
    principal_cents - (current_balance_cents || principal_cents)
  end

  def interest_paid
    # Placeholder: Will be populated from loan_payment records or similar
    0
  end

  def principal_paid_percentage
    return 0 if principal_cents.nil? || principal_cents == 0
    ((principal_paid.to_f / principal_cents) * 100).clamp(0, 100).round(1)
  end

  def interest_paid_percentage
    return 0 if total_interest.nil? || total_interest == 0
    ((interest_paid.to_f / total_interest) * 100).clamp(0, 100).round(1)
  end

  def periods_paid
    current_period || 0
  end

  def total_periods
    return 0 if term_years.nil?
    case payment_period
    when 'monthly'
      (term_years * 12).to_i
    when 'biweekly'
      (term_years * 26).to_i
    when 'weekly'
      (term_years * 52).to_i
    when 'yearly'
      term_years.to_i
    else
      (term_years * 12).to_i
    end
  end

  def years_remaining
    return term_years if periods_paid == 0
    remaining_periods = total_periods - periods_paid
    case payment_period
    when 'monthly'
      (remaining_periods.to_f / 12).round(1)
    when 'biweekly'
      (remaining_periods.to_f / 26).round(1)
    when 'weekly'
      (remaining_periods.to_f / 52).round(1)
    when 'yearly'
      remaining_periods.to_f
    else
      (remaining_periods.to_f / 12).round(1)
    end
  end
end
