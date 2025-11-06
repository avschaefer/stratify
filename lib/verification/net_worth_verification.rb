# frozen_string_literal: true

# Verification script for net worth and portfolio calculations
# Tests asset, liability, and net worth calculations
# Run with: rails runner lib/verification/net_worth_verification.rb

module Verification
  class NetWorthVerification
    def self.run
      puts "=" * 80
      puts "Net Worth & Portfolio Calculation Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      
      # Create a mock user object for testing
      user = OpenStruct.new(
        portfolios: [],
        loans: [],
        savings_accounts: []
      )
      
      # Test Case 1: Empty user (no data)
      puts "Test Case 1: Empty user (no portfolios, loans, or savings)"
      puts "-" * 80
      net_worth_service = NetWorthService.new(user: user)
      
      total_assets = net_worth_service.total_assets
      total_liabilities = net_worth_service.total_liabilities
      net_worth = net_worth_service.net_worth
      monthly_savings = net_worth_service.monthly_savings
      
      puts "Total Assets: $#{total_assets}"
      puts "Total Liabilities: $#{total_liabilities}"
      puts "Net Worth: $#{net_worth}"
      puts "Monthly Savings: $#{monthly_savings}"
      
      if total_assets.zero? && total_liabilities.zero? && net_worth.zero?
        puts "✓ PASS - Empty user handled correctly"
      else
        errors << "Empty user not handled correctly"
        puts "✗ FAIL - Should return zeros for empty user"
      end
      puts ""
      
      # Test Case 2: Portfolio value calculation
      puts "Test Case 2: Portfolio value calculation"
      puts "-" * 80
      portfolio1 = OpenStruct.new(purchase_price: 100.0, quantity: 10, asset_type: 'stock')
      portfolio2 = OpenStruct.new(purchase_price: 50.0, quantity: 20, asset_type: 'bond')
      
      user.portfolios = [portfolio1, portfolio2]
      
      portfolio_service = PortfolioValueService.new(user: user)
      
      value1 = portfolio_service.portfolio_value(portfolio1)
      value2 = portfolio_service.portfolio_value(portfolio2)
      total_value = portfolio_service.total_value
      
      expected_value1 = 100.0 * 10
      expected_value2 = 50.0 * 20
      expected_total = expected_value1 + expected_value2
      
      puts "Portfolio 1: $100 x 10 = $#{value1} (expected $#{expected_value1})"
      puts "Portfolio 2: $50 x 20 = $#{value2} (expected $#{expected_value2})"
      puts "Total Portfolio Value: $#{total_value} (expected $#{expected_total})"
      
      if value1 == expected_value1 && value2 == expected_value2 && total_value == expected_total
        puts "✓ PASS - Portfolio value calculation correct"
      else
        errors << "Portfolio value calculation incorrect"
        puts "✗ FAIL - Portfolio values don't match expected"
      end
      puts ""
      
      # Test Case 3: Asset allocation
      puts "Test Case 3: Asset allocation calculation"
      puts "-" * 80
      allocation = portfolio_service.asset_allocation
      percentages = portfolio_service.allocation_percentages
      
      puts "Asset Allocation:"
      allocation.each do |asset_type, value|
        percentage = percentages[asset_type]
        puts "  #{asset_type}: $#{value.round(2)} (#{percentage}%)"
      end
      
      stock_allocation = allocation['stock'] || 0
      bond_allocation = allocation['bond'] || 0
      expected_stock_percent = (stock_allocation / total_value * 100).round(2)
      
      if allocation['stock'] == 1000 && allocation['bond'] == 1000 && percentages.values.sum.round(2) == 100.0
        puts "✓ PASS - Asset allocation correct"
      else
        errors << "Asset allocation calculation incorrect"
        puts "✗ FAIL - Allocation percentages don't sum to 100%"
      end
      puts ""
      
      # Test Case 4: Net worth with loans
      puts "Test Case 4: Net worth with loans (liabilities)"
      puts "-" * 80
      loan1 = OpenStruct.new(principal: 50_000)
      loan2 = OpenStruct.new(principal: 25_000)
      
      user.loans = [loan1, loan2]
      
      net_worth_service2 = NetWorthService.new(user: user)
      
      total_assets2 = net_worth_service2.total_assets
      total_liabilities2 = net_worth_service2.total_liabilities
      net_worth2 = net_worth_service2.net_worth
      
      expected_liabilities = 50_000 + 25_000
      expected_net_worth = total_value - expected_liabilities
      
      puts "Total Assets: $#{total_assets2}"
      puts "Total Liabilities: $#{total_liabilities2} (expected $#{expected_liabilities})"
      puts "Net Worth: $#{net_worth2} (expected $#{expected_net_worth})"
      
      if total_liabilities2 == expected_liabilities && net_worth2 == expected_net_worth
        puts "✓ PASS - Net worth calculation correct"
      else
        errors << "Net worth calculation incorrect"
        puts "✗ FAIL - Net worth doesn't match expected"
      end
      puts ""
      
      # Test Case 5: Monthly savings calculation
      puts "Test Case 5: Monthly savings calculation"
      puts "-" * 80
      
      # Mock savings account with snapshots
      snapshot_current = OpenStruct.new(recorded_at: Date.today.beginning_of_month, balance: 15_000)
      snapshot_last = OpenStruct.new(recorded_at: 1.month.ago.beginning_of_month, balance: 12_000)
      
      account = OpenStruct.new(
        monthly_snapshots: OpenStruct.new(
          find_by: ->(date) {
            if date == Date.today.beginning_of_month
              snapshot_current
            elsif date == 1.month.ago.beginning_of_month
              snapshot_last
            else
              nil
            end
          }
        )
      )
      
      user.savings_accounts = [account]
      
      net_worth_service3 = NetWorthService.new(user: user)
      
      monthly_savings = net_worth_service3.monthly_savings
      expected_savings = 15_000 - 12_000
      
      puts "Current Month Balance: $15,000"
      puts "Last Month Balance: $12,000"
      puts "Monthly Savings: $#{monthly_savings} (expected $#{expected_savings})"
      
      if monthly_savings == expected_savings
        puts "✓ PASS - Monthly savings calculation correct"
      else
        errors << "Monthly savings calculation incorrect"
        puts "✗ FAIL - Monthly savings doesn't match expected"
      end
      puts ""
      
      # Test Case 6: Edge cases
      puts "Test Case 6: Edge cases"
      puts "-" * 80
      
      # Null portfolio values
      portfolio_nil = OpenStruct.new(purchase_price: nil, quantity: nil, asset_type: 'stock')
      portfolio_zero = OpenStruct.new(purchase_price: 0, quantity: 0, asset_type: 'bond')
      
      user.portfolios = [portfolio_nil, portfolio_zero]
      portfolio_service_edge = PortfolioValueService.new(user: user)
      
      nil_value = portfolio_service_edge.portfolio_value(portfolio_nil)
      zero_value = portfolio_service_edge.portfolio_value(portfolio_zero)
      
      puts "Portfolio with nil values: $#{nil_value} (should be 0)"
      puts "Portfolio with zero values: $#{zero_value} (should be 0)"
      
      if nil_value.zero? && zero_value.zero?
        puts "✓ PASS - Edge cases handled correctly"
      else
        errors << "Edge cases not handled correctly"
        puts "✗ FAIL - Nil/zero values should result in zero"
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
        puts "Net worth and portfolio calculations are correct."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::NetWorthVerification.run
end

