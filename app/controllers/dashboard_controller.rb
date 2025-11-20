class DashboardController < ApplicationController
  include Exportable
  include ErrorHandler
  
  def index
    begin
      net_worth_service = NetWorthService.new(user: current_user)
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
    # TODO: Calculate actual trends from historical data
    @assets_trend = calculate_assets_trend
    @liabilities_trend = calculate_liabilities_trend
    @net_worth_trend = calculate_net_worth_trend
  end
  
  private
  
  def calculate_assets_trend
    # Calculate year-over-year change in assets
    current_assets = @total_assets
    return 0 if current_assets.zero?
    
    # Get assets from 1 year ago (simplified - using current portfolio value as proxy)
    # In a real implementation, would track historical asset values
    begin
      # For now, estimate based on portfolio growth
      portfolio = current_user.portfolio
      if portfolio&.persisted?
        holdings = portfolio.holdings.holdings
        if holdings.any?
          # Estimate previous year value based on cost basis
          previous_cost_basis = holdings.sum { |h| h.total_cost_basis }
          current_value = holdings.sum { |h| h.current_value }
          
          # Simple estimate: assume linear growth
          if previous_cost_basis > 0
            growth_rate = ((current_value - previous_cost_basis) / previous_cost_basis * 100)
            # Estimate last year's assets
            estimated_last_year = current_assets / (1 + growth_rate / 100.0)
            return ((current_assets - estimated_last_year) / estimated_last_year * 100).round(2) rescue 0
          end
        end
      end
    rescue => e
      Rails.logger.error("Error calculating assets trend: #{e.message}")
    end
    
    0
  end
  
  def calculate_liabilities_trend
    # Calculate year-over-year change in liabilities
    current_liabilities = @total_liabilities
    return 0 if current_liabilities.zero?
    
    # In a real implementation, would track historical liability values
    # For now, return 0 (no change) as placeholder
    0
  end
  
  def calculate_net_worth_trend
    # Calculate year-over-year change in net worth
    current_net_worth = @net_worth
    return 0 if current_net_worth.zero?
    
    # Use assets trend as proxy for net worth trend (simplified)
    @assets_trend
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
