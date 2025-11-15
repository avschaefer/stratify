class Tax < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true }
  validates :gross_income_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :deductions_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :taxable_income_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :tax_paid_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :refund_cents, presence: true, numericality: { only_integer: true }
  
  enum :payment_period, { monthly: 'monthly', quarterly: 'quarterly', yearly: 'yearly' }, default: 'yearly'
  
  def gross_income
    gross_income_cents / 100.0 if gross_income_cents
  end
  
  def gross_income=(value)
    self.gross_income_cents = (value.to_f * 100).round if value
  end
  
  def deductions
    deductions_cents / 100.0 if deductions_cents
  end
  
  def deductions=(value)
    self.deductions_cents = (value.to_f * 100).round if value
  end
  
  def taxable_income
    taxable_income_cents / 100.0 if taxable_income_cents
  end
  
  def taxable_income=(value)
    self.taxable_income_cents = (value.to_f * 100).round if value
  end
  
  def tax_paid
    tax_paid_cents / 100.0 if tax_paid_cents
  end
  
  def tax_paid=(value)
    self.tax_paid_cents = (value.to_f * 100).round if value
  end
  
  def refund
    refund_cents / 100.0 if refund_cents
  end
  
  def refund=(value)
    self.refund_cents = (value.to_f * 100).round if value
  end
  
  def after_tax_income
    gross_income - tax_paid + refund
  end
end

