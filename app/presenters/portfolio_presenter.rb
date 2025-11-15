# frozen_string_literal: true

# Presenter for portfolio data formatting
class PortfolioPresenter
  attr_reader :portfolio, :user
  
  def initialize(portfolio:, user:)
    @portfolio = portfolio
    @user = user
  end
  
  # Format portfolio value
  def formatted_value
    Money.new(amount: portfolio_value, currency: user_currency).formatted
  end
  
  # Format total cost basis
  def formatted_cost_basis
    Money.new(amount: portfolio.total_cost_basis || 0, currency: user_currency).formatted
  end
  
  # Get portfolio value
  def portfolio_value
    portfolio.total_value || 0
  end
  
  # Format holdings count
  def formatted_holdings_count
    portfolio.holdings.count
  end
  
  private
  
  def user_currency
    user.currency || 'USD'
  end
end

