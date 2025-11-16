class DashboardController < ApplicationController
  include Exportable
  include ErrorHandler
  
  def index
    begin
      net_worth_service = Calculations::NetWorthService.new(user: current_user)
      summary = net_worth_service.calculate
      
      @total_assets = summary[:total_assets]
      @total_liabilities = summary[:total_liabilities]
      @net_worth = summary[:net_worth]
      @monthly_savings = summary[:monthly_savings]
      @asset_allocation = summary[:asset_allocation]
      
      # Calculate average cash flow for 3, 6, and 12 months
      # Cash flow = (savings account changes) - (credit card balances) per month
      cash_accounts = current_user.accounts.where(account_type: ['savings', 'checking'])
      credit_card_accounts = current_user.accounts.where(account_type: 'credit_card')
      
      # Calculate cash flow for each of the last 12 months
      cash_flows = []
      (0..11).each do |months_ago|
        month_start = months_ago.months.ago.beginning_of_month
        prev_month_start = (months_ago + 1).months.ago.beginning_of_month
        
        # Change in cash accounts
        cash_change = cash_accounts.sum do |account|
          current_balance = account.balances.find_by(balance_date: month_start)&.amount_cents || 0
          prev_balance = account.balances.find_by(balance_date: prev_month_start)&.amount_cents || 0
          current_balance - prev_balance
        end
        
        # Credit card balances for this month
        credit_card_balance = credit_card_accounts.sum do |account|
          account.balances.find_by(balance_date: month_start)&.amount_cents || 0
        end
        
        # Cash flow = cash change - credit card balance
        cash_flow = (cash_change - credit_card_balance) / 100.0
        cash_flows << cash_flow
      end
      
      # Calculate averages
      @avg_cash_flow_3_months = cash_flows.first(3).sum / 3.0 rescue 0
      @avg_cash_flow_6_months = cash_flows.first(6).sum / 6.0 rescue 0
      @avg_cash_flow_12_months = cash_flows.sum / 12.0 rescue 0
      
    rescue => e
      Rails.logger.error "Dashboard error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Set default values on error
      @total_assets = 0
      @total_liabilities = 0
      @net_worth = 0
      @monthly_savings = 0
      @asset_allocation = {}
      @avg_cash_flow_3_months = 0
      @avg_cash_flow_6_months = 0
      @avg_cash_flow_12_months = 0
      
      flash.now[:alert] = 'Unable to load dashboard data. Please try again.'
    end
    
    # Calculate trends (simplified - would come from historical data)
    @assets_trend = 12.0
    @liabilities_trend = -8.0
    @net_worth_trend = 18.0
  end
  
  def export
    # Placeholder for export functionality
  end
  
  def export_excel
    export_service = ExcelExportService.new(user: current_user)
    stream = export_service.generate
    
    send_data stream.read,
      filename: export_service.filename,
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  rescue => e
    handle_export_error(e)
  end
  
  def export_pdf
    export_service = PdfExportService.new(user: current_user)
    pdf_data = export_service.generate
    
    send_data pdf_data,
      filename: export_service.filename,
      type: "application/pdf",
      disposition: "attachment"
  rescue => e
    handle_export_error(e)
  end
end
