# frozen_string_literal: true

require 'prawn'

# Service for exporting financial data to PDF format
class PdfExportService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate PDF document and return rendered PDF
  def generate
    pdf = Prawn::Document.new
    
    add_header(pdf)
    add_summary_section(pdf)
    add_portfolio_section(pdf)
    add_savings_accounts_section(pdf)
    add_loans_section(pdf)
    
    pdf.render
  end
  
  # Generate filename for export
  def filename
    "financial_dashboard_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  end
  
  private
  
  def add_header(pdf)
    pdf.text "Financial Dashboard Export", size: 20, style: :bold
    pdf.text "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}", size: 10
    pdf.move_down 20
  end
  
  def add_summary_section(pdf)
    pdf.text "Summary", size: 16, style: :bold
    pdf.move_down 10
    
    net_worth_service = NetWorthService.new(user: user)
    summary = net_worth_service.calculate
    
    summary_data = [
      ["Metric", "Value"],
      ["Net Worth", format_currency(summary[:net_worth])],
      ["Total Assets", format_currency(summary[:total_assets])],
      ["Total Liabilities", format_currency(summary[:total_liabilities])],
      ["Net Monthly Savings", format_currency(summary[:monthly_savings])]
    ]
    
    pdf.table(summary_data, header: true, width: pdf.bounds.width)
    pdf.move_down 20
  end
  
  def add_portfolio_section(pdf)
    pdf.text "Portfolio", size: 16, style: :bold
    pdf.move_down 10
    
    portfolio_service = PortfolioValueService.new(user: user)
    portfolio_data = [["Ticker", "Asset Type", "Purchase Date", "Price", "Quantity", "Total Value"]]
    
    user.portfolios.each do |portfolio|
      value = portfolio_service.portfolio_value(portfolio)
      portfolio_data << [
        portfolio.ticker,
        portfolio.asset_type,
        portfolio.purchase_date.to_s,
        format_currency(portfolio.purchase_price || 0),
        format_number(portfolio.quantity || 0),
        format_currency(value)
      ]
    end
    
    portfolio_data << ["Total", "", "", "", "", format_currency(portfolio_service.total_value)]
    pdf.table(portfolio_data, header: true, width: pdf.bounds.width)
    pdf.move_down 20
  end
  
  def add_savings_accounts_section(pdf)
    pdf.text "Savings Accounts", size: 16, style: :bold
    pdf.move_down 10
    
    current_month = Date.today.beginning_of_month
    savings_data = [["Account Name", "Type", "Current Balance"]]
    
    user.savings_accounts.each do |account|
      current_balance = account.monthly_snapshots.find_by(recorded_at: current_month)&.balance || 0
      savings_data << [
        account.name,
        account.account_type,
        format_currency(current_balance)
      ]
    end
    
    pdf.table(savings_data, header: true, width: pdf.bounds.width)
    pdf.move_down 20
  end
  
  def add_loans_section(pdf)
    pdf.text "Loans", size: 16, style: :bold
    pdf.move_down 10
    
    loans_data = [["Name", "Principal", "Interest Rate", "Term (Years)"]]
    
    user.loans.each do |loan|
      loans_data << [
        loan.name,
        format_currency(loan.principal || 0),
        "#{loan.interest_rate}%",
        loan.term_years.to_s
      ]
    end
    
    total_principal = user.loans.sum(:principal) || 0
    loans_data << ["Total Principal", format_currency(total_principal), "", ""]
    pdf.table(loans_data, header: true, width: pdf.bounds.width)
  end
  
  def format_currency(amount)
    "$#{number_with_delimiter(amount.round(2))}"
  end
  
  def format_number(number, precision: 2)
    number_with_precision(number, precision: precision)
  end
  
  def number_with_delimiter(number, delimiter: ',')
    parts = number.to_s.split('.')
    parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}") + (parts[1] ? ".#{parts[1]}" : '')
  end
  
  def number_with_precision(number, precision: 2)
    sprintf("%.#{precision}f", number)
  end
end

