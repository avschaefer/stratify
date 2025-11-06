# frozen_string_literal: true

# Verification script for insurance analysis calculations
# Tests insurance policy metrics and coverage calculations
# Run with: rails runner lib/verification/insurance_calculation_verification.rb

module Verification
  class InsuranceCalculationVerification
    def self.run
      puts "=" * 80
      puts "Insurance Analysis Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      
      # Create mock user and policy
      user = OpenStruct.new(
        portfolios: [],
        savings_accounts: []
      )
      
      # Test Case 1: Basic premium calculations
      puts "Test Case 1: Premium calculations"
      puts "-" * 80
      policy1 = OpenStruct.new(
        premium: 100,
        coverage_amount: 500_000,
        term_years: 20,
        policy_type: 'life'
      )
      
      service1 = InsuranceAnalysisService.new(policy: policy1, user: user)
      
      monthly_premium = service1.monthly_premium
      annual_premium = service1.annual_premium
      total_cost = service1.total_cost
      
      expected_annual = 100 * 12
      expected_total = expected_annual * 20
      
      puts "Monthly Premium: $#{monthly_premium} (expected $100)"
      puts "Annual Premium: $#{annual_premium} (expected $#{expected_annual})"
      puts "Total Cost (20 years): $#{total_cost} (expected $#{expected_total})"
      
      if monthly_premium == 100 && annual_premium == expected_annual && total_cost == expected_total
        puts "✓ PASS - Premium calculations correct"
      else
        errors << "Premium calculations incorrect"
        puts "✗ FAIL - Premium calculations don't match expected"
      end
      puts ""
      
      # Test Case 2: Cost per thousand calculation
      puts "Test Case 2: Cost per thousand dollars of coverage"
      puts "-" * 80
      cost_per_thousand = service1.cost_per_thousand
      expected_cost_per_thousand = (1200.0 / 500_000 * 1000).round(2)
      
      puts "Coverage Amount: $500,000"
      puts "Annual Premium: $1,200"
      puts "Cost per $1,000: $#{cost_per_thousand} (expected $#{expected_cost_per_thousand})"
      
      if cost_per_thousand == expected_cost_per_thousand
        puts "✓ PASS - Cost per thousand calculation correct"
      else
        errors << "Cost per thousand calculation incorrect"
        puts "✗ FAIL - Cost per thousand doesn't match expected"
      end
      puts ""
      
      # Test Case 3: Life insurance suggested coverage
      puts "Test Case 3: Life insurance suggested coverage"
      puts "-" * 80
      
      portfolio = OpenStruct.new(purchase_price: 200_000, quantity: 1, asset_type: 'stock')
      snapshot = OpenStruct.new(recorded_at: Date.today.beginning_of_month, balance: 50_000)
      account = OpenStruct.new(
        monthly_snapshots: OpenStruct.new(
          find_by: ->(date) { snapshot if date == Date.today.beginning_of_month }
        )
      )
      
      user.portfolios = [portfolio]
      user.savings_accounts = [account]
      
      policy_life = OpenStruct.new(
        premium: 150,
        coverage_amount: 400_000,
        term_years: 30,
        policy_type: 'life'
      )
      
      service_life = InsuranceAnalysisService.new(policy: policy_life, user: user)
      
      suggested_coverage = service_life.suggested_coverage
      total_assets = 200_000 + 50_000
      expected_suggested = total_assets * 2
      
      puts "Total Assets: $#{total_assets}"
      puts "Suggested Coverage (2x assets): $#{suggested_coverage} (expected $#{expected_suggested})"
      puts "Current Coverage: $400,000"
      
      if suggested_coverage == expected_suggested
        puts "✓ PASS - Suggested coverage calculation correct"
      else
        errors << "Suggested coverage calculation incorrect"
        puts "✗ FAIL - Suggested coverage doesn't match expected"
      end
      puts ""
      
      # Test Case 4: Coverage adequacy percentage
      puts "Test Case 4: Coverage adequacy percentage"
      puts "-" * 80
      adequacy = service_life.coverage_adequacy
      expected_adequacy = (400_000.0 / expected_suggested * 100).round(2)
      
      puts "Current Coverage: $400,000"
      puts "Suggested Coverage: $#{expected_suggested}"
      puts "Coverage Adequacy: #{adequacy}% (expected #{expected_adequacy}%)"
      
      if (adequacy - expected_adequacy).abs < 0.1
        puts "✓ PASS - Coverage adequacy calculation correct"
      else
        errors << "Coverage adequacy calculation incorrect"
        puts "✗ FAIL - Coverage adequacy doesn't match expected"
      end
      puts ""
      
      # Test Case 5: Zero coverage
      puts "Test Case 5: Zero coverage amount"
      puts "-" * 80
      policy_zero = OpenStruct.new(
        premium: 50,
        coverage_amount: 0,
        term_years: 10,
        policy_type: 'life'
      )
      
      service_zero = InsuranceAnalysisService.new(policy: policy_zero, user: user)
      
      cost_per_thousand_zero = service_zero.cost_per_thousand
      adequacy_zero = service_zero.coverage_adequacy
      
      puts "Coverage Amount: $0"
      puts "Cost per $1,000: $#{cost_per_thousand_zero} (should be 0)"
      puts "Coverage Adequacy: #{adequacy_zero}% (should be 0)"
      
      if cost_per_thousand_zero.zero? && adequacy_zero.zero?
        puts "✓ PASS - Zero coverage handled correctly"
      else
        errors << "Zero coverage not handled correctly"
        puts "✗ FAIL - Zero coverage should result in zero metrics"
      end
      puts ""
      
      # Test Case 6: Months remaining calculation
      puts "Test Case 6: Months remaining in term"
      puts "-" * 80
      months_remaining = service1.months_remaining
      expected_months = 20 * 12
      
      puts "Term Years: 20"
      puts "Months Remaining: #{months_remaining} (expected #{expected_months})"
      
      if months_remaining == expected_months
        puts "✓ PASS - Months remaining calculation correct"
      else
        errors << "Months remaining calculation incorrect"
        puts "✗ FAIL - Months remaining doesn't match expected"
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
        puts "Insurance analysis calculations are correct."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::InsuranceCalculationVerification.run
end

