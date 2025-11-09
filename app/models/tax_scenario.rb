class TaxScenario < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :year, presence: true
  validates :income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deductions, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :taxable_income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  # Allow negative refund values to represent taxes owed at filing time
  validates :refund, presence: true, numericality: true
  
  def after_tax_income
    income - tax_paid + refund
  end
end

