class TaxScenario < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :year, presence: true
  validates :income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deductions, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  def taxable_income
    [income - deductions, 0].max
  end
  
  def tax_bracket_2024
    case taxable_income
    when 0..11000
      { rate: 0.10, min: 0, max: 11000 }
    when 11001..44725
      { rate: 0.12, min: 11000, max: 44725 }
    when 44726..95350
      { rate: 0.22, min: 44725, max: 95350 }
    when 95351..201050
      { rate: 0.24, min: 95350, max: 201050 }
    when 201051..502300
      { rate: 0.32, min: 201050, max: 502300 }
    else
      { rate: 0.37, min: 502300, max: Float::INFINITY }
    end
  end
  
  def estimated_tax
    bracket = tax_bracket_2024
    taxable_income * bracket[:rate]
  end
  
  def after_tax_income
    income - estimated_tax
  end
end

