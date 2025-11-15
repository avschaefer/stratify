# frozen_string_literal: true

# Service for calculating portfolio values and asset allocation
class PortfolioValueService
  attr_reader :user
  
  def initialize(user:)
    @user = user
    raise ArgumentError, "User cannot be nil" if user.nil?
  end
  
  # Calculate total portfolio value (sum of all holdings)
  def total_value
    return 0 unless user.respond_to?(:portfolio)
    return 0 if user.portfolio.nil?
    
    user.portfolio.total_value || 0
  rescue => e
    Rails.logger.error "Error calculating portfolio value: #{e.message}"
    0
  end
  
  # Calculate value of a specific portfolio (for backward compatibility)
  def portfolio_value(portfolio)
    return 0 if portfolio.nil?
    portfolio.total_value || 0
  end
  
  # Calculate asset allocation by ticker/asset
  def asset_allocation
    allocation = {}
    
    return allocation unless user.respond_to?(:portfolio)
    return allocation if user.portfolio.nil?
    
    user.portfolio.holdings.each do |holding|
      value = holding.current_value
      ticker = holding.ticker || 'other'
      allocation[ticker] = (allocation[ticker] || 0) + value
    end
    
    allocation
  rescue => e
    Rails.logger.error "Error calculating asset allocation: #{e.message}"
    {}
  end
  
  # Get portfolio value by ticker
  def value_by_ticker(ticker)
    return 0 unless user.respond_to?(:portfolio)
    return 0 if user.portfolio.nil?
    
    user.portfolio.holdings
      .where(ticker: ticker)
      .sum { |h| h.current_value }
  end
  
  # Calculate percentage allocation by ticker
  def allocation_percentages
    total = total_value
    return {} if total.zero?
    
    asset_allocation.transform_values do |value|
      (value / total * 100).round(2)
    end
  end
  
  # Get all holdings
  def holdings
    return [] unless user.respond_to?(:portfolio)
    return [] if user.portfolio.nil?
    user.portfolio.holdings
  end
  
  # Calculate total cost basis
  def total_cost_basis
    return 0 unless user.respond_to?(:portfolio)
    return 0 if user.portfolio.nil?
    user.portfolio.total_cost_basis || 0
  end
end

