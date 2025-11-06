# frozen_string_literal: true

# Verification script for retirement projection calculations
# Tests retirement projection formulas against known financial standards
# Run with: rails runner lib/verification/retirement_calculation_verification.rb

module Verification
  class RetirementCalculationVerification
    def self.run
      puts "=" * 80
      puts "Retirement Projection Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      warnings = []
      
      # Create a test scenario object
      scenario = OpenStruct.new(
        current_savings: 100_000,
        target_amount: 1_000_000,
        monthly_contribution: 500,
        expected_return_rate: 7.0,
        target_date: Date.today + 30.years
      )
      
      # Test Case 1: Standard retirement projection
      # Current: $100,000, Monthly: $500, Return: 7%, Target: $1M, 30 years
      puts "Test Case 1: Standard retirement projection"
      puts "-" * 80
      service1 = RetirementProjectionService.new(scenario: scenario)
      
      projected_value = service1.projected_value
      years_to_goal = service1.years_to_goal
      months_to_goal = service1.months_to_goal
      
      puts "Current Savings: $#{scenario.current_savings}"
      puts "Monthly Contribution: $#{scenario.monthly_contribution}"
      puts "Expected Return: #{scenario.expected_return_rate}%"
      puts "Target Amount: $#{scenario.target_amount}"
      puts "Years to Goal: #{years_to_goal}"
      puts "Months to Goal: #{months_to_goal}"
      puts "Projected Value: $#{projected_value.round(2)}"
      
      # Verify future value formula
      # FV = PV * (1 + r)^n + PMT * (((1 + r)^n - 1) / r)
      monthly_rate = 7.0 / 100.0 / 12.0
      months = 30 * 12
      expected_fv_current = 100_000 * (1 + monthly_rate)**months
      expected_fv_contributions = 500 * (((1 + monthly_rate)**months - 1) / monthly_rate)
      expected_total = expected_fv_current + expected_fv_contributions
      
      diff = (projected_value - expected_total).abs
      puts "Expected (manual calculation): $#{expected_total.round(2)}"
      puts "Difference: $#{diff.round(2)}"
      
      if diff < 100.0
        puts "✓ PASS - Projection within acceptable range"
      else
        errors << "Projection calculation off by $#{diff.round(2)}"
        puts "✗ FAIL - Projection difference too large"
      end
      puts ""
      
      # Test Case 2: Monthly contribution needed calculation
      puts "Test Case 2: Required monthly contribution"
      puts "-" * 80
      contribution_needed = service1.monthly_contribution_needed
      
      # Verify PMT formula: PMT = (FV - PV * (1+r)^n) * r / ((1+r)^n - 1)
      future_value_of_current = 100_000 * (1 + monthly_rate)**months
      needed_from_contributions = 1_000_000 - future_value_of_current
      expected_pmt = needed_from_contributions * monthly_rate / ((1 + monthly_rate)**months - 1)
      
      puts "Current Monthly Contribution: $500"
      puts "Required Monthly Contribution: $#{contribution_needed.round(2)}"
      puts "Expected (manual calculation): $#{expected_pmt.round(2)}"
      
      pmt_diff = (contribution_needed - expected_pmt).abs
      if pmt_diff < 10.0
        puts "✓ PASS - Required contribution calculation correct"
      else
        errors << "Required contribution calculation off by $#{pmt_diff.round(2)}"
        puts "✗ FAIL - Contribution calculation difference too large"
      end
      puts ""
      
      # Test Case 3: Zero return rate
      puts "Test Case 3: Zero return rate"
      puts "-" * 80
      scenario_zero = OpenStruct.new(
        current_savings: 50_000,
        target_amount: 200_000,
        monthly_contribution: 1_000,
        expected_return_rate: 0.0,
        target_date: Date.today + 10.years
      )
      service_zero = RetirementProjectionService.new(scenario: scenario_zero)
      
      projected_zero = service_zero.projected_value
      expected_zero = 50_000 + (1_000 * 10 * 12)
      
      puts "Current: $50,000"
      puts "Monthly Contribution: $1,000"
      puts "Return Rate: 0%"
      puts "Term: 10 years"
      puts "Expected (simple addition): $#{expected_zero}"
      puts "Projected Value: $#{projected_zero.round(2)}"
      
      if (projected_zero - expected_zero).abs < 0.01
        puts "✓ PASS - Zero return rate handled correctly"
      else
        errors << "Zero return rate calculation incorrect"
        puts "✗ FAIL - Zero return rate not handled correctly"
      end
      puts ""
      
      # Test Case 4: Zero contributions
      puts "Test Case 4: Zero monthly contributions"
      puts "-" * 80
      scenario_no_contrib = OpenStruct.new(
        current_savings: 200_000,
        target_amount: 500_000,
        monthly_contribution: 0,
        expected_return_rate: 5.0,
        target_date: Date.today + 20.years
      )
      service_no_contrib = RetirementProjectionService.new(scenario: scenario_no_contrib)
      
      projected_no_contrib = service_no_contrib.projected_value
      expected_no_contrib = 200_000 * (1 + (5.0 / 100.0 / 12.0))**(20 * 12)
      
      puts "Current: $200,000"
      puts "Monthly Contribution: $0"
      puts "Return Rate: 5%"
      puts "Term: 20 years"
      puts "Expected (compound interest only): $#{expected_no_contrib.round(2)}"
      puts "Projected Value: $#{projected_no_contrib.round(2)}"
      
      diff_no_contrib = (projected_no_contrib - expected_no_contrib).abs
      if diff_no_contrib < 100.0
        puts "✓ PASS - Zero contributions handled correctly"
      else
        errors << "Zero contributions calculation incorrect"
        puts "✗ FAIL - Zero contributions not handled correctly"
      end
      puts ""
      
      # Test Case 5: Past target date
      puts "Test Case 5: Past target date"
      puts "-" * 80
      scenario_past = OpenStruct.new(
        current_savings: 100_000,
        target_amount: 200_000,
        monthly_contribution: 500,
        expected_return_rate: 7.0,
        target_date: Date.today - 5.years
      )
      service_past = RetirementProjectionService.new(scenario: scenario_past)
      
      years_past = service_past.years_to_goal
      projected_past = service_past.projected_value
      
      puts "Target Date: #{scenario_past.target_date} (in the past)"
      puts "Years to Goal: #{years_past}"
      puts "Projected Value: $#{projected_past.round(2)}"
      
      if years_past == 0 && projected_past == scenario_past.current_savings
        puts "✓ PASS - Past target date handled correctly"
      else
        errors << "Past target date not handled correctly"
        puts "✗ FAIL - Should return current savings when target date is in past"
      end
      puts ""
      
      # Test Case 6: Progress percentage
      puts "Test Case 6: Progress percentage calculation"
      puts "-" * 80
      scenario_progress = OpenStruct.new(
        current_savings: 250_000,
        target_amount: 1_000_000,
        monthly_contribution: 1_000,
        expected_return_rate: 7.0,
        target_date: Date.today + 20.years
      )
      service_progress = RetirementProjectionService.new(scenario: scenario_progress)
      
      progress = service_progress.progress_percentage
      projected = service_progress.projected_value
      expected_progress = (projected / scenario_progress.target_amount * 100).round(2)
      
      puts "Projected Value: $#{projected.round(2)}"
      puts "Target Amount: $1,000,000"
      puts "Expected Progress: #{expected_progress}%"
      puts "Calculated Progress: #{progress}%"
      
      if (progress - expected_progress).abs < 0.1
        puts "✓ PASS - Progress percentage correct"
      else
        errors << "Progress percentage calculation incorrect"
        puts "✗ FAIL - Progress percentage difference too large"
      end
      puts ""
      
      # Test Case 7: Withdrawal phase calculations
      puts "Test Case 7: Withdrawal phase"
      puts "-" * 80
      withdrawal_data = service1.withdrawal_data(retirement_years: 30, monthly_withdrawal: 3_000)
      
      projected_at_retirement = service1.projected_value_at_retirement
      puts "Projected Value at Retirement: $#{projected_at_retirement.round(2)}"
      puts "Monthly Withdrawal: $3,000"
      puts "Retirement Years: 30"
      puts "Withdrawal Data Points: #{withdrawal_data[:projected_savings].count}"
      
      # Verify first withdrawal point
      if withdrawal_data[:projected_savings].any?
        first_month = withdrawal_data[:projected_savings].first
        expected_first_month = (projected_at_retirement * (1 + monthly_rate) - 3_000).round(2)
        
        puts "First Month Value: $#{first_month[:value]}"
        puts "Expected: $#{expected_first_month}"
        
        if (first_month[:value] - expected_first_month).abs < 1.0
          puts "✓ PASS - Withdrawal phase calculation correct"
        else
          errors << "Withdrawal phase calculation incorrect"
          puts "✗ FAIL - Withdrawal calculation difference too large"
        end
      else
        errors << "Withdrawal data not generated"
        puts "✗ FAIL - No withdrawal data generated"
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
        puts "Retirement projection calculations are mathematically correct."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::RetirementCalculationVerification.run
end

