# frozen_string_literal: true

# Service for calculating portfolio values and asset allocation
class PortfolioValueService
  attr_reader :user
  
  def initialize(user:)
    @user = user
    raise ArgumentError, "User cannot be nil" if user.nil?
  end
  
  # Calculate total portfolio value (sum of all portfolio positions)
  def total_value
    return 0 unless user.respond_to?(:portfolios)
    
    user.portfolios.sum do |portfolio|
      portfolio_value(portfolio)
    end
  rescue => e
    Rails.logger.error "Error calculating portfolio value: #{e.message}"
    0
  end
  
  # Calculate value of a specific portfolio
  def portfolio_value(portfolio)
    return 0 if portfolio.nil?
    (portfolio.purchase_price || 0) * (portfolio.quantity || 0)
  end
  
  # Calculate asset allocation by asset type
  def asset_allocation
    allocation = {}
    
    return allocation unless user.respond_to?(:portfolios)
    
    user.portfolios.each do |portfolio|
      value = portfolio_value(portfolio)
      asset_type = portfolio.asset_type || 'other'
      allocation[asset_type] = (allocation[asset_type] || 0) + value
    end
    
    allocation
  rescue => e
    Rails.logger.error "Error calculating asset allocation: #{e.message}"
    {}
  end
  
  # Get portfolio value by asset type
  def value_by_asset_type(asset_type)
    user.portfolios
      .where(asset_type: asset_type)
      .sum { |p| portfolio_value(p) }
  end
  
  # Calculate percentage allocation by asset type
  def allocation_percentages
    total = total_value
    return {} if total.zero?
    
    asset_allocation.transform_values do |value|
      (value / total * 100).round(2)
    end
  end
  
  # Get all active portfolios
  def active_portfolios
    user.portfolios.where(status: 'active')
  end
  
  # Calculate total active portfolio value
  def active_value
    active_portfolios.sum { |p| portfolio_value(p) }
  end
end

