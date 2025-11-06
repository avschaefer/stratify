# frozen_string_literal: true

# Value object representing interest rates
# Handles APR and APY conversions and period calculations
class InterestRate
  attr_reader :rate, :rate_type, :compounding_period
  
  RATE_TYPES = %w[apr apy].freeze
  COMPOUNDING_PERIODS = %w[daily monthly quarterly annually].freeze
  
  def initialize(rate:, rate_type: 'apr', compounding_period: 'monthly')
    @rate = BigDecimal(rate.to_s)
    @rate_type = rate_type.to_s.downcase
    @compounding_period = compounding_period.to_s.downcase
    
    validate!
  end
  
  # Convert APY to APR
  def to_apr
    return self if rate_type == 'apr'
    
    compounding_per_year = compounding_periods_per_year(compounding_period)
    apr_rate = compounding_per_year * (((1 + (rate / 100.0)) ** (1.0 / compounding_per_year)) - 1) * 100
    
    InterestRate.new(
      rate: apr_rate,
      rate_type: 'apr',
      compounding_period: compounding_period
    )
  end
  
  # Convert APR to APY
  def to_apy
    return self if rate_type == 'apy'
    
    compounding_per_year = compounding_periods_per_year(compounding_period)
    apy_rate = ((1 + (rate / 100.0) / compounding_per_year) ** compounding_per_year - 1) * 100
    
    InterestRate.new(
      rate: apy_rate,
      rate_type: 'apy',
      compounding_period: compounding_period
    )
  end
  
  # Get periodic rate (monthly, quarterly, etc.)
  def periodic_rate(periods_per_year:)
    apr_rate = rate_type == 'apr' ? rate : to_apr.rate
    apr_rate / 100.0 / periods_per_year
  end
  
  # Get effective annual rate
  def effective_annual_rate(payments_per_year:)
    apr_rate = rate_type == 'apr' ? rate : to_apr.rate
    compounding_per_year = compounding_periods_per_year(compounding_period)
    
    periodic_rate = apr_rate / 100.0 / compounding_per_year
    effective_rate = ((1 + periodic_rate) ** (compounding_per_year.to_f / payments_per_year)) - 1
    
    effective_rate * payments_per_year * 100
  end
  
  # Get monthly rate
  def monthly_rate
    periodic_rate(periods_per_year: 12)
  end
  
  # Get daily rate
  def daily_rate
    periodic_rate(periods_per_year: 365)
  end
  
  def to_f
    rate.to_f
  end
  
  def to_s
    "#{rate.round(4)}% #{rate_type.upcase}"
  end
  
  private
  
  def validate!
    raise ArgumentError, "Invalid rate type: #{rate_type}" unless RATE_TYPES.include?(rate_type)
    raise ArgumentError, "Invalid compounding period: #{compounding_period}" unless COMPOUNDING_PERIODS.include?(compounding_period)
  end
  
  def compounding_periods_per_year(period)
    case period
    when 'daily' then 365
    when 'monthly' then 12
    when 'quarterly' then 4
    when 'annually' then 1
    else 12
    end
  end
end

