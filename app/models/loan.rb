class Loan < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :principal, presence: true, numericality: { greater_than: 0 }
  validates :interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_years, presence: true, numericality: { greater_than: 0 }
  
  enum :status, { draft: 0, active: 1 }
  
  def monthly_payment
    return 0 if principal.nil? || interest_rate.nil? || term_years.nil?
    
    monthly_rate = interest_rate / 100.0 / 12.0
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
end

