# frozen_string_literal: true

# Service for calculating net worth, assets, liabilities, and monthly trends
class NetWorthService
  attr_reader :user
  
  def initialize(user:)
    @user = user
    raise ArgumentError, "User cannot be nil" if user.nil?
  end
  
  # Calculate total assets (portfolios + savings accounts)
  def total_assets
    portfolio_value_service.total_value + total_savings
  end
  
  # Calculate total liabilities (sum of all loan current balances)
  # Uses current_balance_cents if available, otherwise falls back to principal_cents
  def total_liabilities
    return 0 unless user.respond_to?(:loans)
    user.loans.sum do |loan|
      # Use current balance if available, otherwise use original principal
      balance_cents = loan.current_balance_cents || loan.principal_cents || 0
      balance_cents
    end / 100.0
  rescue => e
    Rails.logger.error "Error calculating liabilities: #{e.message}"
    0
  end
  
  # Calculate net worth (assets - liabilities)
  def net_worth
    total_assets - total_liabilities
  end
  
  # Calculate monthly savings (difference between current and last month's savings)
  def monthly_savings
    current_total = total_savings_for_month(Date.today.beginning_of_month)
    last_total = total_savings_for_month(1.month.ago.beginning_of_month)
    current_total - last_total
  end
  
  # Calculate total savings for a specific month
  def total_savings_for_month(month_date)
    return 0 unless user.respond_to?(:accounts)
    
    user.accounts.sum do |account|
      account.balances
        .find_by(balance_date: month_date)&.amount_cents || 0
    end / 100.0
  rescue => e
    Rails.logger.error "Error calculating savings for month: #{e.message}"
    0
  end
  
  # Calculate monthly trends over a specified number of months
  def monthly_trends(months: 12)
    trends = {}
    
    (0..(months - 1)).each do |months_ago|
      month_date = months_ago.months.ago.beginning_of_month
      
      # Calculate assets for this month
      portfolio_assets = portfolio_value_service.total_value # Using current portfolio values as proxy
      savings = total_savings_for_month(month_date)
      assets = portfolio_assets + savings
      
      # Calculate liabilities (using current loans as proxy - in real app would track historical)
      liabilities = total_liabilities
      
      net_worth = assets - liabilities
      
      trends[month_date] = {
        net_worth: net_worth,
        assets: assets,
        liabilities: liabilities
      }
    end
    
    trends
  end
  
  # Get asset allocation (delegates to PortfolioValueService)
  def asset_allocation
    portfolio_value_service.asset_allocation
  end
  
  # Calculate comprehensive summary
  def calculate
    {
      total_assets: total_assets.round(2),
      total_liabilities: total_liabilities.round(2),
      net_worth: net_worth.round(2),
      monthly_savings: monthly_savings.round(2),
      asset_allocation: asset_allocation,
      monthly_trends: monthly_trends
    }
  end
  
  private
  
  def portfolio_value_service
    @portfolio_value_service ||= PortfolioValueService.new(user: user)
  end
  
  def total_savings
    total_savings_for_month(Date.today.beginning_of_month)
  end
end

