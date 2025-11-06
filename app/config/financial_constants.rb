# frozen_string_literal: true

# Financial constants and configuration
module FinancialConstants
  # Default values
  DEFAULT_RETIREMENT_RETURN_RATE = 7.0
  DEFAULT_RETIREMENT_YEARS = 30
  
  # Calculation constants
  MONTHS_PER_YEAR = 12
  DAYS_PER_YEAR = 365
  
  # Chart defaults
  DEFAULT_CHART_DAYS = 365
  DEFAULT_HISTORICAL_MONTHS = 24
  DEFAULT_FUTURE_MONTHS_LIMIT = 60
  
  # Export defaults
  DEFAULT_EXPORT_FORMAT = 'xlsx'
  
  # Validation ranges
  MIN_INTEREST_RATE = 0.0
  MAX_INTEREST_RATE = 100.0
  MIN_PRINCIPAL = 0.01
  MIN_TERM_YEARS = 0.01
  MAX_TERM_YEARS = 100.0
end

