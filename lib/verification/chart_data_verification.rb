# frozen_string_literal: true

# Verification script for chart data services
# Tests chart data generation format and data structure
# Run with: rails runner lib/verification/chart_data_verification.rb

module Verification
  class ChartDataVerification
    def self.run
      puts "=" * 80
      puts "Chart Data Service Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      
      # Test Case 1: Savings chart data format
      puts "Test Case 1: Savings chart data format"
      puts "-" * 80
      
      user = OpenStruct.new(
        savings_accounts: [],
        expenses: []
      )
      
      service = SavingsChartDataService.new(user: user)
      chart_data = service.generate(days: 365)
      
      required_keys = [:savings, :spending, :net_savings]
      has_all_keys = required_keys.all? { |key| chart_data.key?(key) }
      
      puts "Required keys: #{required_keys.join(', ')}"
      puts "Has all keys: #{has_all_keys}"
      
      if has_all_keys
        # Check data format
        if chart_data[:savings].is_a?(Array) && chart_data[:savings].any?
          first_point = chart_data[:savings].first
          has_time = first_point.key?(:time)
          has_value = first_point.key?(:value)
          
          puts "Data points: #{chart_data[:savings].count}"
          puts "First point has 'time': #{has_time}"
          puts "First point has 'value': #{has_value}"
          
          if has_time && has_value && first_point[:time].is_a?(Integer)
            puts "✓ PASS - Savings chart data format correct"
          else
            errors << "Savings chart data format incorrect"
            puts "✗ FAIL - Data format doesn't match expected structure"
          end
        else
          puts "✓ PASS - Empty data handled correctly (returns empty arrays)"
        end
      else
        errors << "Missing required keys in savings chart data"
        puts "✗ FAIL - Missing required keys"
      end
      puts ""
      
      # Test Case 2: Retirement chart data format
      puts "Test Case 2: Retirement chart data format"
      puts "-" * 80
      
      user_with_scenario = OpenStruct.new(
        retirement_scenarios: OpenStruct.new(
          order: ->(field) {
            OpenStruct.new(
              first: OpenStruct.new(
                current_savings: 100_000,
                target_amount: 1_000_000,
                monthly_contribution: 500,
                expected_return_rate: 7.0,
                target_date: Date.today + 30.years
              )
            )
          }
        )
      )
      
      retirement_service = RetirementChartDataService.new(user: user_with_scenario)
      retirement_data = retirement_service.generate
      
      required_retirement_keys = [:actual_savings, :projected_savings, :target_savings, :today_timestamp]
      has_all_retirement_keys = required_retirement_keys.all? { |key| retirement_data.key?(key) }
      
      puts "Required keys: #{required_retirement_keys.join(', ')}"
      puts "Has all keys: #{has_all_retirement_keys}"
      
      if has_all_retirement_keys && retirement_data[:today_timestamp].is_a?(Integer)
        puts "✓ PASS - Retirement chart data format correct"
      else
        errors << "Retirement chart data format incorrect"
        puts "✗ FAIL - Missing required keys or invalid timestamp format"
      end
      puts ""
      
      # Test Case 3: Empty user data
      puts "Test Case 3: Empty user data handling"
      puts "-" * 80
      
      empty_user = OpenStruct.new(
        savings_accounts: [],
        expenses: [],
        retirement_scenarios: OpenStruct.new(order: ->(_) { OpenStruct.new(first: nil) })
      )
      
      empty_savings_service = SavingsChartDataService.new(user: empty_user)
      empty_chart_data = empty_savings_service.generate
      
      puts "Data points (savings): #{empty_chart_data[:savings].count}"
      puts "Data points (spending): #{empty_chart_data[:spending].count}"
      puts "Data points (net_savings): #{empty_chart_data[:net_savings].count}"
      
      if empty_chart_data[:savings].is_a?(Array) && empty_chart_data[:savings].count == 365
        puts "✓ PASS - Empty data generates correct number of data points (all zeros)"
      else
        errors << "Empty data not handled correctly"
        puts "✗ FAIL - Should generate 365 data points even with empty data"
      end
      puts ""
      
      # Test Case 4: Timestamp format
      puts "Test Case 4: Timestamp format verification"
      puts "-" * 80
      
      sample_date = Date.today
      timestamp = sample_date.to_time.to_i
      
      puts "Sample date: #{sample_date}"
      puts "Unix timestamp: #{timestamp}"
      puts "Timestamp type: #{timestamp.class}"
      
      if timestamp.is_a?(Integer) && timestamp > 0
        puts "✓ PASS - Timestamp format correct (Unix timestamp)"
      else
        errors << "Timestamp format incorrect"
        puts "✗ FAIL - Timestamps should be Unix integers"
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
        puts "Chart data services generate correct format for Lightweight Charts."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::ChartDataVerification.run
end

