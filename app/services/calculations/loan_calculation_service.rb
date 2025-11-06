# frozen_string_literal: true

# Service for calculating loan payments, amortization schedules, and related metrics
# Handles APR/APY conversions and various payment frequencies
class LoanCalculationService
  attr_reader :principal, :interest_rate, :term_years, :rate_type, :payment_frequency, :compounding_period
  
  def initialize(principal:, interest_rate:, term_years:, rate_type: 'apr', payment_frequency: 'monthly', compounding_period: 'monthly')
    @principal = principal.to_f
    @interest_rate = interest_rate.to_f
    @term_years = term_years.to_f
    @rate_type = rate_type.to_s.downcase
    @payment_frequency = payment_frequency.to_s.downcase
    @compounding_period = compounding_period.to_s.downcase
    
    validate!
  end
  
  def calculate
    rate = InterestRate.new(
      rate: interest_rate,
      rate_type: rate_type,
      compounding_period: compounding_period
    )
    
    # Convert to APR if needed
    apr_rate = rate.rate_type == 'apr' ? rate : rate.to_apr
    
    # Calculate periods per year
    payments_per_year = periods_per_year(payment_frequency)
    compounding_per_year = periods_per_year(compounding_period)
    
    # Calculate effective periodic rate
    periodic_rate = apr_rate.periodic_rate(periods_per_year: compounding_per_year)
    effective_rate = calculate_effective_rate(periodic_rate, compounding_per_year, payments_per_year)
    
    # Calculate total payments
    total_payments = (term_years * payments_per_year).to_i
    
    # Calculate periodic payment
    periodic_payment = calculate_periodic_payment(principal, effective_rate, total_payments)
    
    # Generate amortization schedule
    amortization_schedule = generate_amortization_schedule(principal, periodic_payment, effective_rate, total_payments)
    
    # Calculate totals
    total_interest = amortization_schedule.sum { |p| p[:interest] }
    total_amount = principal + total_interest
    
    # Calculate averages
    avg_principal_per_payment = principal / total_payments
    avg_interest_per_payment = total_interest / total_payments
    
    # Calculate effective annual rate
    effective_annual_rate = apr_rate.effective_annual_rate(payments_per_year: payments_per_year)
    
    {
      periodic_payment: periodic_payment.round(2),
      total_payments: total_payments,
      total_principal: principal.round(2),
      total_interest: total_interest.round(2),
      total_amount: total_amount.round(2),
      principal_per_payment: avg_principal_per_payment.round(2),
      interest_per_payment: avg_interest_per_payment.round(2),
      effective_rate: effective_annual_rate.round(2),
      amortization_schedule: amortization_schedule
    }
  end
  
  private
  
  def validate!
    raise ArgumentError, 'Principal must be positive' if principal <= 0
    raise ArgumentError, 'Interest rate must be non-negative' if interest_rate < 0
    raise ArgumentError, 'Term years must be positive' if term_years <= 0
    raise ArgumentError, "Invalid rate type: #{rate_type}" unless ['apr', 'apy'].include?(rate_type)
    raise ArgumentError, "Invalid payment frequency: #{payment_frequency}" unless valid_payment_frequency?
    raise ArgumentError, "Invalid compounding period: #{compounding_period}" unless valid_compounding_period?
  end
  
  def valid_payment_frequency?
    %w[weekly biweekly monthly quarterly].include?(payment_frequency)
  end
  
  def valid_compounding_period?
    %w[daily monthly quarterly annually].include?(compounding_period)
  end
  
  def periods_per_year(period)
    case period
    when 'weekly' then 52
    when 'biweekly' then 26
    when 'monthly' then 12
    when 'quarterly' then 4
    when 'daily' then 365
    when 'annually' then 1
    else 12
    end
  end
  
  def calculate_effective_rate(periodic_rate, compounding_per_year, payments_per_year)
    # Adjust rate for payment frequency vs compounding frequency
    ((1 + periodic_rate) ** (compounding_per_year.to_f / payments_per_year)) - 1
  end
  
  def calculate_periodic_payment(principal, effective_rate, total_payments)
    if effective_rate == 0
      principal / total_payments
    else
      principal * (effective_rate * (1 + effective_rate)**total_payments) / ((1 + effective_rate)**total_payments - 1)
    end
  end
  
  def generate_amortization_schedule(principal, periodic_payment, effective_rate, total_payments)
    balance = principal
    schedule = []
    
    total_payments.times do |payment_num|
      interest_payment = balance * effective_rate
      principal_payment = periodic_payment - interest_payment
      balance -= principal_payment
      
      # Ensure balance doesn't go negative
      if balance < 0
        principal_payment += balance
        balance = 0
      end
      
      schedule << {
        payment_number: payment_num + 1,
        payment_amount: periodic_payment.round(2),
        principal: principal_payment.round(2),
        interest: interest_payment.round(2),
        balance: balance.round(2)
      }
      
      break if balance <= 0
    end
    
    schedule
  end
end

