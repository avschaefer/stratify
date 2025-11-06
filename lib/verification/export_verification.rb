# frozen_string_literal: true

# Verification script for export services
# Tests Excel and PDF export generation
# Run with: rails runner lib/verification/export_verification.rb

module Verification
  class ExportVerification
    def self.run
      puts "=" * 80
      puts "Export Service Verification"
      puts "=" * 80
      puts ""
      
      errors = []
      
      # Create mock user
      user = OpenStruct.new(
        portfolios: [],
        savings_accounts: [],
        loans: []
      )
      
      # Test Case 1: Excel export with empty data
      puts "Test Case 1: Excel export with empty data"
      puts "-" * 80
      
      begin
        excel_service = ExcelExportService.new(user: user)
        stream = excel_service.generate
        
        filename = excel_service.filename
        
        puts "Filename: #{filename}"
        puts "Stream readable: #{stream.respond_to?(:read)}"
        
        if filename.match?(/financial_dashboard_\d{8}_\d{6}\.xlsx/)
          puts "✓ PASS - Filename format correct"
        else
          errors << "Excel filename format incorrect"
          puts "✗ FAIL - Filename doesn't match expected pattern"
        end
        
        if stream.respond_to?(:read)
          data = stream.read
          puts "File size: #{data.length} bytes"
          
          if data.length > 0
            puts "✓ PASS - Excel file generated successfully"
          else
            errors << "Excel file is empty"
            puts "✗ FAIL - Generated file is empty"
          end
        else
          errors << "Excel stream is not readable"
          puts "✗ FAIL - Stream doesn't have read method"
        end
      rescue => e
        errors << "Excel export failed: #{e.message}"
        puts "✗ FAIL - Excel export error: #{e.message}"
      end
      puts ""
      
      # Test Case 2: PDF export with empty data
      puts "Test Case 2: PDF export with empty data"
      puts "-" * 80
      
      begin
        pdf_service = PdfExportService.new(user: user)
        pdf_data = pdf_service.generate
        
        filename = pdf_service.filename
        
        puts "Filename: #{filename}"
        puts "PDF data type: #{pdf_data.class}"
        
        if filename.match?(/financial_dashboard_\d{8}_\d{6}\.pdf/)
          puts "✓ PASS - Filename format correct"
        else
          errors << "PDF filename format incorrect"
          puts "✗ FAIL - Filename doesn't match expected pattern"
        end
        
        if pdf_data.is_a?(String) && pdf_data.length > 0
          puts "PDF size: #{pdf_data.length} bytes"
          puts "✓ PASS - PDF file generated successfully"
        else
          errors << "PDF file is empty or invalid"
          puts "✗ FAIL - Generated PDF is empty or invalid"
        end
      rescue => e
        errors << "PDF export failed: #{e.message}"
        puts "✗ FAIL - PDF export error: #{e.message}"
      end
      puts ""
      
      # Test Case 3: Excel export with data
      puts "Test Case 3: Excel export with sample data"
      puts "-" * 80
      
      portfolio = OpenStruct.new(
        ticker: 'AAPL',
        asset_type: 'stock',
        purchase_date: Date.today,
        purchase_price: 150.0,
        quantity: 10,
        status: 'active'
      )
      
      loan = OpenStruct.new(
        name: 'Test Loan',
        principal: 50_000,
        interest_rate: 4.5,
        term_years: 30,
        status: 'active'
      )
      
      user_with_data = OpenStruct.new(
        portfolios: [portfolio],
        loans: [loan],
        savings_accounts: []
      )
      
      begin
        excel_service2 = ExcelExportService.new(user: user_with_data)
        stream2 = excel_service2.generate
        
        data2 = stream2.read
        puts "Excel file size with data: #{data2.length} bytes"
        
        if data2.length > 1000 # Should be larger than empty file
          puts "✓ PASS - Excel export includes data"
        else
          errors << "Excel export with data may be incomplete"
          puts "⚠ WARNING - File size seems small for data"
        end
      rescue => e
        errors << "Excel export with data failed: #{e.message}"
        puts "✗ FAIL - #{e.message}"
      end
      puts ""
      
      # Test Case 4: PDF export with data
      puts "Test Case 4: PDF export with sample data"
      puts "-" * 80
      
      begin
        pdf_service2 = PdfExportService.new(user: user_with_data)
        pdf_data2 = pdf_service2.generate
        
        puts "PDF file size with data: #{pdf_data2.length} bytes"
        
        if pdf_data2.length > 1000
          puts "✓ PASS - PDF export includes data"
        else
          errors << "PDF export with data may be incomplete"
          puts "⚠ WARNING - File size seems small for data"
        end
      rescue => e
        errors << "PDF export with data failed: #{e.message}"
        puts "✗ FAIL - #{e.message}"
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
        puts "Export services generate valid Excel and PDF files."
        return true
      end
    end
  end
end

# Run verification if script is executed directly
if __FILE__ == $0
  Verification::ExportVerification.run
end

