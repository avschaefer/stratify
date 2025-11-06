# frozen_string_literal: true

# Comprehensive edge case verification script
# Tests empty data scenarios, boundary conditions, and error handling
# Run with: rails runner lib/verification/edge_cases_verification.rb

module Verification
  class EdgeCasesVerification
    def self.run
      puts "=" * 80
      puts "Edge Cases & Error Handling Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      
      # Test Case 1: All services with nil user
      puts "Test Case 1: Nil user handling"
      puts "-" * 80
      
      begin
        NetWorthService.new(user: nil)
        errors << "Should have rejected nil user"
        puts "✗ FAIL - Should reject nil user"
      rescue ArgumentError => e
        puts "✓ PASS - Nil user correctly rejected: #{e.message}"
      end
      puts ""
      
      # Test Case 2: Empty user (no portfolios, loans, savings)
      puts "Test Case 2: Empty user data"
      puts "-" * 80
      
      empty_user = OpenStruct.new(
        portfolios: [],
        loans: [],
        savings_accounts: [],
        expenses: [],
        retirement_scenarios: [],
        insurance_policies: [],
        tax_scenarios: []
      )
      
      begin
        net_worth_service = NetWorthService.new(user: empty_user)
        summary = net_worth_service.calculate
        
        puts "Total Assets: $#{summary[:total_assets]} (should be 0)"
        puts "Total Liabilities: $#{summary[:total_liabilities]} (should be 0)"
        puts "Net Worth: $#{summary[:net_worth]} (should be 0)"
        
        if summary[:total_assets].zero? && summary[:total_liabilities].zero? && summary[:net_worth].zero?
          puts "✓ PASS - Empty user handled correctly"
        else
          errors << "Empty user not handled correctly"
          puts "✗ FAIL - Should return zeros for empty user"
        end
      rescue => e
        errors << "Empty user test failed: #{e.message}"
        puts "✗ FAIL - Error: #{e.message}"
      end
      puts ""
      
      # Test Case 3: Very large numbers
      puts "Test Case 3: Very large numbers"
      puts "-" * 80
      
      begin
        service = LoanCalculationService.new(
          principal: 1_000_000_000,
          interest_rate: 15.0,
          term_years: 30,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        result = service.calculate
        
        puts "Principal: $1,000,000,000"
        puts "Monthly Payment: $#{result[:periodic_payment]}"
        puts "Total Amount: $#{result[:total_amount]}"
        
        if result[:periodic_payment] > 0 && result[:total_amount] > 1_000_000_000
          puts "✓ PASS - Very large numbers handled"
        else
          errors << "Very large numbers not handled correctly"
          puts "✗ FAIL - Large number calculation failed"
        end
      rescue => e
        errors << "Large numbers test failed: #{e.message}"
        puts "✗ FAIL - Error: #{e.message}"
      end
      puts ""
      
      # Test Case 4: Very small numbers (near zero)
      puts "Test Case 4: Very small numbers"
      puts "-" * 80
      
      begin
        service = LoanCalculationService.new(
          principal: 10.0,
          interest_rate: 0.01,
          term_years: 1,
          rate_type: 'apr',
          payment_frequency: 'monthly',
          compounding_period: 'monthly'
        )
        result = service.calculate
        
        puts "Principal: $10"
        puts "Interest Rate: 0.01%"
        puts "Monthly Payment: $#{result[:periodic_payment]}"
        
        if result[:periodic_payment] > 0 && result[:periodic_payment] < 10
          puts "✓ PASS - Very small numbers handled"
        else
          errors << "Very small numbers not handled correctly"
          puts "✗ FAIL - Small number calculation failed"
        end
      rescue => e
        errors << "Small numbers test failed: #{e.message}"
        puts "✗ FAIL - Error: #{e.message}"
      end
      puts ""
      
      # Test Case 5: Negative values (should be rejected)
      puts "Test Case 5: Negative values rejection"
      puts "-" * 80
      
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
        puts "✗ FAIL - Should reject negative principal"
      rescue ArgumentError
        puts "✓ PASS - Negative principal correctly rejected"
      end
      
      begin
        TaxCalculationService.new(income: -1000, deductions: 0, year: 2024)
        errors << "Should have rejected negative income"
        puts "✗ FAIL - Should reject negative income"
      rescue ArgumentError
        puts "✓ PASS - Negative income correctly rejected"
      end
      puts ""
      
      # Test Case 6: Missing required fields
      puts "Test Case 6: Missing required fields"
      puts "-" * 80
      
      portfolio_nil = OpenStruct.new(
        purchase_price: nil,
        quantity: nil,
        asset_type: 'stock'
      )
      
      portfolio_service = PortfolioValueService.new(user: OpenStruct.new(portfolios: [portfolio_nil]))
      value = portfolio_service.portfolio_value(portfolio_nil)
      
      puts "Portfolio with nil values: $#{value} (should be 0)"
      if value.zero?
        puts "✓ PASS - Nil values handled correctly"
      else
        errors << "Nil values not handled correctly"
        puts "✗ FAIL - Should return 0 for nil values"
      end
      puts ""
      
      # Test Case 7: Date edge cases
      puts "Test Case 7: Date edge cases"
      puts "-" * 80
      
      scenario_past = OpenStruct.new(
        current_savings: 100_000,
        target_amount: 200_000,
        monthly_contribution: 500,
        expected_return_rate: 7.0,
        target_date: Date.today - 10.years
      )
      
      retirement_service = RetirementProjectionService.new(scenario: scenario_past)
      years_to_goal = retirement_service.years_to_goal
      
      puts "Target Date: #{scenario_past.target_date} (in the past)"
      puts "Years to Goal: #{years_to_goal} (should be 0)"
      
      if years_to_goal == 0
        puts "✓ PASS - Past dates handled correctly"
      else
        errors << "Past dates not handled correctly"
        puts "✗ FAIL - Should return 0 for past dates"
      end
      puts ""
      
      # Summary
      puts "=" * 80
      puts "Verification Summary"
      puts "=" * 80
      puts "Errors: #{errors.count}"
      puts ""
      
      if errors.any?
        puts "Errors found:"
        errors.each { |e| puts "  - #{e}" }
        puts ""
        return false
      else
        puts "✓ ALL TESTS PASSED"
        puts ""
        puts "Edge cases are handled correctly."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::EdgeCasesVerification.run
end

