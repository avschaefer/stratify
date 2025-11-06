# frozen_string_literal: true

# Verification script for loan calculations
# Tests loan amortization formulas against known financial standards
# Run with: rails runner lib/verification/loan_calculation_verification.rb

module Verification
  class LoanCalculationVerification
    def self.run
      puts "=" * 80
      puts "Loan Calculation Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      warnings = []
      
      # Test Case 1: Standard 30-year mortgage (most common)
      # Principal: $300,000, APR: 5%, Monthly payments, 30 years
      # Expected monthly payment: ~$1,610.46
      puts "Test Case 1: Standard 30-year mortgage"
      puts "-" * 80
      service1 = LoanCalculationService.new(
        principal: 300_000,
        interest_rate: 5.0,
        term_years: 30,
        rate_type: 'apr',
        payment_frequency: 'monthly',
        compounding_period: 'monthly'
      )
      result1 = service1.calculate
      expected_payment = 1610.46
      actual_payment = result1[:periodic_payment]
      diff = (actual_payment - expected_payment).abs
      
      puts "Principal: $300,000"
      puts "Interest Rate: 5% APR"
      puts "Term: 30 years"
      puts "Expected Monthly Payment: $#{expected_payment}"
      puts "Calculated Monthly Payment: $#{actual_payment}"
      puts "Difference: $#{diff.round(2)}"
      
      if diff < 1.0
        puts "✓ PASS - Payment within acceptable range"
      else
        errors << "Payment calculation off by $#{diff.round(2)}"
        puts "✗ FAIL - Payment difference too large"
      end
      
      # Verify total interest
      total_expected = 300_000 + (result1[:total_interest])
      puts "Total Amount (Principal + Interest): $#{total_expected.round(2)}"
      puts "Total Interest: $#{result1[:total_interest].round(2)}"
      puts ""
      
      # Test Case 2: APY conversion
      # Principal: $100,000, APY: 6%, Monthly payments, 5 years
      puts "Test Case 2: APY to APR conversion"
      puts "-" * 80
      service2 = LoanCalculationService.new(
        principal: 100_000,
        interest_rate: 6.0,
        term_years: 5,
        rate_type: 'apy',
        payment_frequency: 'monthly',
        compounding_period: 'monthly'
      )
      result2 = service2.calculate
      
      rate_obj = InterestRate.new(rate: 6.0, rate_type: 'apy', compounding_period: 'monthly')
      apr_rate = rate_obj.to_apr
      
      puts "APY: 6%"
      puts "Converted APR: #{apr_rate.rate.round(4)}%"
      puts "Monthly Payment: $#{result2[:periodic_payment].round(2)}"
      puts "Total Payments: #{result2[:total_payments]}"
      
      # Verify APR conversion is correct
      # APY = (1 + APR/n)^n - 1, so APR should be slightly less than APY
      if apr_rate.rate < 6.0
        puts "✓ PASS - APR correctly less than APY"
      else
        errors << "APY to APR conversion incorrect"
        puts "✗ FAIL - APR should be less than APY"
      end
      puts ""
      
      # Test Case 3: Zero interest loan
      puts "Test Case 3: Zero interest loan"
      puts "-" * 80
      service3 = LoanCalculationService.new(
        principal: 10_000,
        interest_rate: 0.0,
        term_years: 5,
        rate_type: 'apr',
        payment_frequency: 'monthly',
        compounding_period: 'monthly'
      )
      result3 = service3.calculate
      
      expected_zero_payment = 10_000.0 / (5 * 12)
      puts "Principal: $10,000"
      puts "Interest Rate: 0%"
      puts "Term: 5 years"
      puts "Expected Monthly Payment: $#{expected_zero_payment.round(2)}"
      puts "Calculated Monthly Payment: $#{result3[:periodic_payment].round(2)}"
      puts "Total Interest: $#{result3[:total_interest].round(2)}"
      
      if result3[:total_interest].zero? && (result3[:periodic_payment] - expected_zero_payment).abs < 0.01
        puts "✓ PASS - Zero interest handled correctly"
      else
        errors << "Zero interest calculation incorrect"
        puts "✗ FAIL - Zero interest not handled correctly"
      end
      puts ""
      
      # Test Case 4: Different payment frequencies
      puts "Test Case 4: Payment frequency variations"
      puts "-" * 80
      frequencies = {
        'weekly' => 52,
        'biweekly' => 26,
        'monthly' => 12,
        'quarterly' => 4
      }
      
      frequencies.each do |freq, periods_per_year|
        service = LoanCalculationService.new(
          principal: 50_000,
          interest_rate: 4.5,
          term_years: 10,
          rate_type: 'apr',
          payment_frequency: freq,
          compounding_period: 'monthly'
        )
        result = service.calculate
        
        expected_total_payments = 10 * periods_per_year
        puts "#{freq.capitalize}:"
        puts "  Expected Total Payments: #{expected_total_payments}"
        puts "  Calculated Total Payments: #{result[:total_payments]}"
        puts "  Payment Amount: $#{result[:periodic_payment].round(2)}"
        
        if result[:total_payments] == expected_total_payments
          puts "  ✓ PASS"
        else
          errors << "#{freq} payment frequency calculation incorrect"
          puts "  ✗ FAIL"
        end
      end
      puts ""
      
      # Test Case 5: Amortization schedule verification
      puts "Test Case 5: Amortization schedule totals"
      puts "-" * 80
      service5 = LoanCalculationService.new(
        principal: 200_000,
        interest_rate: 4.0,
        term_years: 15,
        rate_type: 'apr',
        payment_frequency: 'monthly',
        compounding_period: 'monthly'
      )
      result5 = service5.calculate
      
      schedule = result5[:amortization_schedule]
      sum_principal = schedule.sum { |p| p[:principal] }
      sum_interest = schedule.sum { |p| p[:interest] }
      final_balance = schedule.last[:balance]
      
      puts "Principal: $200,000"
      puts "Total Principal Paid: $#{sum_principal.round(2)}"
      puts "Total Interest Paid: $#{sum_interest.round(2)}"
      puts "Final Balance: $#{final_balance.round(2)}"
      puts "Total from Schedule: $#{(sum_principal + sum_interest).round(2)}"
      puts "Total Amount: $#{result5[:total_amount].round(2)}"
      
      principal_diff = (sum_principal - 200_000).abs
      total_diff = ((sum_principal + sum_interest) - result5[:total_amount]).abs
      
      if principal_diff < 0.01 && total_diff < 0.01 && final_balance < 0.01
        puts "✓ PASS - Amortization schedule balances correctly"
      else
        errors << "Amortization schedule totals don't match"
        puts "✗ FAIL - Schedule totals don't match"
        puts "  Principal difference: $#{principal_diff.round(2)}"
        puts "  Total difference: $#{total_diff.round(2)}"
        puts "  Final balance: $#{final_balance.round(2)}"
      end
      puts ""
      
      # Test Case 6: Edge cases
      puts "Test Case 6: Edge cases"
      puts "-" * 80
      
      # Very high interest rate
      begin
        service6a = LoanCalculationService.new(
          principal: 10_000,
          interest_rate: 25.0,
          term_years: 3,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        result6a = service6a.calculate
        puts "High interest (25% APR): Payment = $#{result6a[:periodic_payment].round(2)}"
        puts "  ✓ PASS - High interest handled"
      rescue => e
        errors << "High interest rate failed: #{e.message}"
        puts "  ✗ FAIL - #{e.message}"
      end
      
      # Very short term
      begin
        service6b = LoanCalculationService.new(
          principal: 5_000,
          interest_rate: 3.5,
          term_years: 0.5,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        result6b = service6b.calculate
        puts "Short term (6 months): Payment = $#{result6b[:periodic_payment].round(2)}"
        puts "  ✓ PASS - Short term handled"
      rescue => e
        errors << "Short term failed: #{e.message}"
        puts "  ✗ FAIL - #{e.message}"
      end
      
      # Invalid inputs
      begin
        LoanCalculationService.new(
          principal: -1000,
          interest_rate: 5.0,
          term_years: 5,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        errors << "Should have rejected negative principal"
        puts "  ✗ FAIL - Should reject negative principal"
      rescue ArgumentError
        puts "  ✓ PASS - Negative principal correctly rejected"
      end
      
      begin
        LoanCalculationService.new(
          principal: 1000,
          interest_rate: 5.0,
          term_years: 0,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        errors << "Should have rejected zero term"
        puts "  ✗ FAIL - Should reject zero term"
      rescue ArgumentError
        puts "  ✓ PASS - Zero term correctly rejected"
      end
      puts ""
      
      # Summary
      puts "=" * 80
      puts "Verification Summary"
      puts "=" * 80
      puts "Errors: #{errors.count}"
      puts "Warnings: #{warnings.count}"
      puts ""
      
      if errors.any?
        puts "Errors found:"
        errors.each { |e| puts "  - #{e}" }
        puts ""
        return false
      else
        puts "✓ ALL TESTS PASSED"
        puts ""
        puts "Loan calculations are mathematically correct and match financial standards."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::LoanCalculationVerification.run
end

