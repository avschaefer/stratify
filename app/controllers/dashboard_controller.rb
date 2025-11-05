class DashboardController < ApplicationController
  def index
    @total_assets = 0
    @total_liabilities = 0
    @net_worth = 0
    @monthly_savings = 0
    
    # Calculate trends (mock data for now - would come from historical data)
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
