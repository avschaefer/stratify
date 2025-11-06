# frozen_string_literal: true

# Verification script for tax calculations
# Tests tax bracket calculations against 2024 IRS tax brackets
# Run with: rails runner lib/verification/tax_calculation_verification.rb

module Verification
  class TaxCalculationVerification
    def self.run
      puts "=" * 80
      puts "Tax Calculation Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      warnings = []
      
      # Test Case 1: 10% bracket ($0 - $11,000)
      puts "Test Case 1: 10% tax bracket"
      puts "-" * 80
      service1 = TaxCalculationService.new(income: 10_000, deductions: 0, year: 2024)
      result1 = service1.calculate
      
      expected_tax = 10_000 * 0.10
      puts "Income: $10,000"
      puts "Deductions: $0"
      puts "Taxable Income: $#{result1[:taxable_income]}"
      puts "Expected Tax (10%): $#{expected_tax}"
      puts "Calculated Tax: $#{result1[:estimated_tax]}"
      puts "Tax Bracket: #{result1[:tax_bracket]}%"
      
      if (result1[:estimated_tax] - expected_tax).abs < 0.01 && result1[:tax_bracket] == 10
        puts "✓ PASS - 10% bracket calculation correct"
      else
        errors << "10% bracket calculation incorrect"
        puts "✗ FAIL - Calculation doesn't match expected"
      end
      puts ""
      
      # Test Case 2: 12% bracket ($11,001 - $44,725)
      puts "Test Case 2: 12% tax bracket"
      puts "-" * 80
      service2 = TaxCalculationService.new(income: 30_000, deductions: 0, year: 2024)
      result2 = service2.calculate
      
      # Progressive: 10% on first $11,000 + 12% on remaining $19,000
      expected_tax = (11_000 * 0.10) + (19_000 * 0.12)
      puts "Income: $30,000"
      puts "Expected Tax (progressive): $#{expected_tax.round(2)}"
      puts "Calculated Tax: $#{result2[:estimated_tax]}"
      puts "Tax Bracket: #{result2[:tax_bracket]}%"
      
      diff = (result2[:estimated_tax] - expected_tax).abs
      if diff < 1.0 && result2[:tax_bracket] == 12
        puts "✓ PASS - 12% bracket calculation correct"
      else
        errors << "12% bracket calculation incorrect (diff: $#{diff.round(2)})"
        puts "✗ FAIL - Progressive calculation incorrect"
      end
      puts ""
      
      # Test Case 3: 22% bracket ($44,726 - $95,350)
      puts "Test Case 3: 22% tax bracket"
      puts "-" * 80
      service3 = TaxCalculationService.new(income: 80_000, deductions: 0, year: 2024)
      result3 = service3.calculate
      
      # Progressive: 10% on $11,000 + 12% on $33,725 + 22% on $35,274
      expected_tax = (11_000 * 0.10) + (33_725 * 0.12) + (35_274 * 0.22)
      puts "Income: $80,000"
      puts "Expected Tax (progressive): $#{expected_tax.round(2)}"
      puts "Calculated Tax: $#{result3[:estimated_tax]}"
      puts "Tax Bracket: #{result3[:tax_bracket]}%"
      
      diff = (result3[:estimated_tax] - expected_tax).abs
      if diff < 1.0 && result3[:tax_bracket] == 22
        puts "✓ PASS - 22% bracket calculation correct"
      else
        errors << "22% bracket calculation incorrect (diff: $#{diff.round(2)})"
        puts "✗ FAIL - Progressive calculation incorrect"
      end
      puts ""
      
      # Test Case 4: Standard deduction
      puts "Test Case 4: Standard deduction"
      puts "-" * 80
      service4 = TaxCalculationService.new(income: 60_000, deductions: 14_600, year: 2024)
      result4 = service4.calculate
      
      taxable_income = 60_000 - 14_600
      expected_tax = (11_000 * 0.10) + (33_725 * 0.12) + (870 * 0.22)
      puts "Income: $60,000"
      puts "Standard Deduction: $14,600"
      puts "Taxable Income: $#{taxable_income} (should be $#{result4[:taxable_income]})"
      puts "Expected Tax: $#{expected_tax.round(2)}"
      puts "Calculated Tax: $#{result4[:estimated_tax]}"
      
      if result4[:taxable_income] == taxable_income && (result4[:estimated_tax] - expected_tax).abs < 1.0
        puts "✓ PASS - Deductions handled correctly"
      else
        errors << "Deduction calculation incorrect"
        puts "✗ FAIL - Deduction calculation incorrect"
      end
      puts ""
      
      # Test Case 5: Zero income
      puts "Test Case 5: Zero income"
      puts "-" * 80
      service5 = TaxCalculationService.new(income: 0, deductions: 0, year: 2024)
      result5 = service5.calculate
      
      puts "Income: $0"
      puts "Taxable Income: $#{result5[:taxable_income]}"
      puts "Estimated Tax: $#{result5[:estimated_tax]}"
      
      if result5[:estimated_tax].zero? && result5[:taxable_income].zero?
        puts "✓ PASS - Zero income handled correctly"
      else
        errors << "Zero income not handled correctly"
        puts "✗ FAIL - Zero income should result in zero tax"
      end
      puts ""
      
      # Test Case 6: Deductions exceed income
      puts "Test Case 6: Deductions exceed income"
      puts "-" * 80
      service6 = TaxCalculationService.new(income: 10_000, deductions: 15_000, year: 2024)
      result6 = service6.calculate
      
      puts "Income: $10,000"
      puts "Deductions: $15,000"
      puts "Taxable Income: $#{result6[:taxable_income]}"
      puts "Estimated Tax: $#{result6[:estimated_tax]}"
      
      if result6[:taxable_income].zero? && result6[:estimated_tax].zero?
        puts "✓ PASS - Excess deductions handled correctly"
      else
        errors << "Excess deductions not handled correctly"
        puts "✗ FAIL - Taxable income should be 0 when deductions exceed income"
      end
      puts ""
      
      # Test Case 7: Effective tax rate
      puts "Test Case 7: Effective tax rate"
      puts "-" * 80
      service7 = TaxCalculationService.new(income: 100_000, deductions: 14_600, year: 2024)
      result7 = service7.calculate
      
      taxable = 100_000 - 14_600
      expected_tax = (11_000 * 0.10) + (33_725 * 0.12) + (40_674 * 0.22)
      expected_effective_rate = (expected_tax / 100_000 * 100).round(2)
      
      puts "Income: $100,000"
      puts "Tax: $#{result7[:estimated_tax]}"
      puts "Expected Effective Rate: #{expected_effective_rate}%"
      puts "Calculated Effective Rate: #{result7[:effective_rate]}%"
      
      if (result7[:effective_rate] - expected_effective_rate).abs < 0.5
        puts "✓ PASS - Effective rate calculation correct"
      else
        errors << "Effective rate calculation incorrect"
        puts "✗ FAIL - Effective rate difference too large"
      end
      puts ""
      
      # Test Case 8: Highest bracket
      puts "Test Case 8: Highest tax bracket (37%)"
      puts "-" * 80
      service8 = TaxCalculationService.new(income: 600_000, deductions: 20_000, year: 2024)
      result8 = service8.calculate
      
      puts "Income: $600,000"
      puts "Deductions: $20,000"
      puts "Taxable Income: $#{result8[:taxable_income]}"
      puts "Tax Bracket: #{result8[:tax_bracket]}%"
      puts "Estimated Tax: $#{result8[:estimated_tax]}"
      
      if result8[:tax_bracket] == 37
        puts "✓ PASS - Highest bracket identification correct"
      else
        errors << "Highest bracket not identified correctly"
        puts "✗ FAIL - Should be in 37% bracket"
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
        puts "NOTE: The tax calculation uses a simplified progressive formula."
        puts "For exact IRS calculations, consider using IRS tax tables or more"
        puts "complex bracket accumulation logic."
        puts ""
        return false
      else
        puts "✓ ALL TESTS PASSED"
        puts ""
        puts "Tax calculations are mathematically correct."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::TaxCalculationVerification.run
end

