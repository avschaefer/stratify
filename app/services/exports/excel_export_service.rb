# frozen_string_literal: true

require 'axlsx'

# Service for exporting financial data to Excel format
class ExcelExportService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate Excel file and return IO stream
  def generate
    package = Axlsx::Package.new
    workbook = package.workbook
    
    add_summary_sheet(workbook)
    add_portfolio_sheet(workbook)
    add_savings_accounts_sheet(workbook)
    add_loans_sheet(workbook)
    
    package.to_stream
  end
  
  # Generate filename for export
  def filename
    "financial_dashboard_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx"
  end
  
  private
  
  def add_summary_sheet(workbook)
    workbook.add_worksheet(name: "Summary") do |sheet|
      sheet.add_row ["Financial Dashboard Export", "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"]
      sheet.add_row []
      
      net_worth_service = NetWorthService.new(user: user)
      summary = net_worth_service.calculate
      
      sheet.add_row ["Metric", "Value"]
      sheet.add_row ["Net Worth", format_currency(summary[:net_worth])]
      sheet.add_row ["Total Assets", format_currency(summary[:total_assets])]
      sheet.add_row ["Total Liabilities", format_currency(summary[:total_liabilities])]
      sheet.add_row ["Net Monthly Savings", format_currency(summary[:monthly_savings])]
    end
  end
  
  def add_portfolio_sheet(workbook)
    workbook.add_worksheet(name: "Portfolio") do |sheet|
      sheet.add_row ["Ticker", "Asset Type", "Purchase Date", "Purchase Price", "Quantity", "Total Value", "Status"]
      
      portfolio_service = PortfolioValueService.new(user: user)
      
      user.portfolios.each do |portfolio|
        value = portfolio_service.portfolio_value(portfolio)
        sheet.add_row [
          portfolio.ticker,
          portfolio.asset_type,
          portfolio.purchase_date,
          portfolio.purchase_price,
          portfolio.quantity,
          value,
          portfolio.status
        ]
      end
      
      sheet.add_row ["Total", "", "", "", "", portfolio_service.total_value, ""]
    end
  end
  
  def add_savings_accounts_sheet(workbook)
    workbook.add_worksheet(name: "Savings Accounts") do |sheet|
      sheet.add_row ["Account Name", "Type", "Current Balance", "Notes"]
      
      current_month = Date.today.beginning_of_month
      
      user.savings_accounts.each do |account|
        current_balance = account.monthly_snapshots.find_by(recorded_at: current_month)&.balance || 0
        sheet.add_row [account.name, account.account_type, current_balance, account.notes]
      end
    end
  end
  
  def add_loans_sheet(workbook)
    workbook.add_worksheet(name: "Loans") do |sheet|
      sheet.add_row ["Name", "Principal", "Interest Rate", "Term (Years)", "Status"]
      
      user.loans.each do |loan|
        sheet.add_row [
          loan.name,
          loan.principal,
          "#{loan.interest_rate}%",
          loan.term_years,
          loan.status
        ]
      end
      
      total_principal = user.loans.sum(:principal) || 0
      sheet.add_row ["Total Principal", total_principal, "", "", ""]
    end
  end
  
  def format_currency(amount)
    "$#{number_with_delimiter(amount.round(2))}"
  end
  
  def number_with_delimiter(number, delimiter: ',')
    parts = number.to_s.split('.')
    parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}") + (parts[1] ? ".#{parts[1]}" : '')
  end
end

