# frozen_string_literal: true

# Service for calculating tax obligations based on income, deductions, and tax year
class TaxCalculationService
  attr_reader :income, :deductions, :year
  
  def initialize(income:, deductions: 0, year: Date.today.year)
    @income = income.to_f
    @deductions = deductions.to_f
    @year = year.to_i
    
    validate!
  end
  
  # Calculate taxable income (income minus deductions, minimum 0)
  def taxable_income
    [income - deductions, 0].max
  end
  
  # Determine tax bracket for the given taxable income and year
  def tax_bracket
    brackets = TaxBrackets.for_year(year)
    taxable = taxable_income
    
    brackets.find { |bracket| taxable >= bracket[:min] && taxable <= bracket[:max] } ||
      brackets.last
  end
  
  # Calculate estimated tax using progressive brackets
  def estimated_tax
    brackets = TaxBrackets.for_year(year)
    taxable = taxable_income
    
    return 0 if taxable <= 0
    
    # Calculate progressive tax (proper bracket accumulation)
    total_tax = 0.0
    remaining_income = taxable
    
    brackets.each do |bracket|
      bracket_min = bracket[:min]
      bracket_max = bracket[:max] == Float::INFINITY ? Float::INFINITY : bracket[:max]
      
      # Skip if income hasn't reached this bracket yet
      next if taxable <= bracket_min
      
      # Calculate amount in this bracket
      if taxable > bracket_max
        # Income exceeds this bracket - tax entire bracket range
        bracket_range = bracket_max - bracket_min + 1
        total_tax += bracket_range * bracket[:rate]
      else
        # Income falls within this bracket - tax only the portion in this bracket
        amount_in_bracket = taxable - bracket_min + 1
        total_tax += amount_in_bracket * bracket[:rate]
        break # No more brackets needed
      end
    end
    
    total_tax
  end
  
  # Calculate after-tax income
  def after_tax_income
    income - estimated_tax
  end
  
  # Calculate effective tax rate (tax as percentage of total income)
  def effective_rate
    return 0 if income <= 0
    (estimated_tax / income * 100).round(2)
  end
  
  # Get all tax bracket information
  def bracket_info
    bracket = tax_bracket
    {
      rate: bracket[:rate] * 100,
      min: bracket[:min],
      max: bracket[:max] == Float::INFINITY ? nil : bracket[:max]
    }
  end
  
  # Get comprehensive calculation results
  def calculate
    {
      income: income.round(2),
      deductions: deductions.round(2),
      taxable_income: taxable_income.round(2),
      estimated_tax: estimated_tax.round(2),
      after_tax_income: after_tax_income.round(2),
      effective_rate: effective_rate,
      tax_bracket: bracket_info[:rate],
      bracket_min: bracket_info[:min],
      bracket_max: bracket_info[:max]
    }
  end
  
  private
  
  def validate!
    raise ArgumentError, 'Income must be non-negative' if income < 0
    raise ArgumentError, 'Deductions must be non-negative' if deductions < 0
    raise ArgumentError, "Tax brackets not available for year: #{year}" unless TaxBrackets.available_years.include?(year)
  end
end

