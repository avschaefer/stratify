class DashboardController < ApplicationController
  def index
    # Calculate totals from user's actual data
    @total_assets = current_user.portfolios.map { |p| (p.purchase_price || 0) * (p.quantity || 0) }.sum
    @total_liabilities = current_user.loans.sum(:principal) || 0
    @net_worth = @total_assets - @total_liabilities
    
    # Calculate monthly savings from savings accounts
    current_month_snapshots = current_user.savings_accounts.map { |a| a.monthly_snapshots.find_by(recorded_at: Date.today.beginning_of_month) }.compact
    last_month_snapshots = current_user.savings_accounts.map { |a| a.monthly_snapshots.find_by(recorded_at: 1.month.ago.beginning_of_month) }.compact
    current_total = current_month_snapshots.sum(&:balance) || 0
    last_total = last_month_snapshots.sum(&:balance) || 0
    @monthly_savings = current_total - last_total
    
    # Calculate trends (simplified - would come from historical data)
    @assets_trend = 12.0
    @liabilities_trend = -8.0
    @net_worth_trend = 18.0
    
    @asset_allocation = {}
    @monthly_trends = {}
  end
  
  def export
    # Placeholder for export functionality
  end
end
