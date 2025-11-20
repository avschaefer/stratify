# frozen_string_literal: true

# Service for calculating portfolio values and asset allocation
class PortfolioValueService
  attr_reader :user
  
  def initialize(user:)
    @user = user
    raise ArgumentError, "User cannot be nil" if user.nil?
  end
  
  # Calculate total portfolio value (sum of all holdings, excluding trades)
  def total_value
    return 0 unless user.respond_to?(:portfolio)
    return 0 if user.portfolio.nil?
    
    # Use portfolio.total_value which filters to holdings only
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
  
  # Calculate asset allocation by asset type (stocks, bonds, crypto, etc.)
  def asset_allocation
    allocation = {}
    
    return allocation unless user.respond_to?(:portfolio)
    return allocation if user.portfolio.nil?
    
    # Only use holdings (not trades) for asset allocation
    user.portfolio.holdings.holdings.each do |holding|
      value = holding.current_value
      next if value.zero?
      
      asset_type = categorize_asset_type(holding.ticker)
      allocation[asset_type] = (allocation[asset_type] || 0) + value
    end
    
    # Add debt/liabilities to allocation
    if user.respond_to?(:loans)
      user.loans.each do |loan|
        balance = (loan.current_balance_cents || loan.principal_cents || 0) / 100.0
        next if balance.zero?
        
        debt_type = categorize_debt_type(loan.name)
        allocation[debt_type] = (allocation[debt_type] || 0) + balance
      end
    end
    
    allocation
  rescue => e
    Rails.logger.error "Error calculating asset allocation: #{e.message}"
    {}
  end
  
  private
  
  def categorize_asset_type(ticker)
    return 'Other' if ticker.blank?
    
    ticker_upper = ticker.upcase
    
    # Check if crypto (contains /USD or known crypto tickers)
    if ticker_upper.include?('/USD') || ticker_upper.include?('/USDT') || ticker_upper.include?('/BTC')
      return 'Crypto'
    end
    
    crypto_tickers = %w[BTC ETH BNB SOL ADA XRP DOGE DOT AVAX MATIC LTC UNI LINK ATOM ETC XLM]
    if crypto_tickers.include?(ticker_upper.split('/').first)
      return 'Crypto'
    end
    
    # Check if bond (common bond tickers or patterns)
    if ticker_upper.match?(/\A[A-Z]{1,3}\d{2,4}\z/) || ticker_upper.include?('BOND') || ticker_upper.include?('TREASURY')
      return 'Bonds'
    end
    
    # Default to stocks
    'Stocks'
  end
  
  def categorize_debt_type(loan_name)
    return 'Other Debt' if loan_name.blank?
    
    name_lower = loan_name.downcase
    
    if name_lower.include?('mortgage') || name_lower.include?('home') || name_lower.include?('house')
      return 'Mortgage'
    elsif name_lower.include?('auto') || name_lower.include?('car') || name_lower.include?('vehicle')
      return 'Auto Loan'
    elsif name_lower.include?('student') || name_lower.include?('education')
      return 'Student Loan'
    elsif name_lower.include?('credit') || name_lower.include?('card')
      return 'Credit Card'
    elsif name_lower.include?('personal')
      return 'Personal Loan'
    else
      return 'Other Debt'
    end
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
  
  # Calculate total cost basis (only holdings, not trades)
  def total_cost_basis
    return 0 unless user.respond_to?(:portfolio)
    return 0 if user.portfolio.nil?
    # Use portfolio.total_cost_basis which filters to holdings only
    user.portfolio.total_cost_basis || 0
  end
end

