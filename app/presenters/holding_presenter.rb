# frozen_string_literal: true

# Presenter for holding data formatting
class HoldingPresenter
  attr_reader :holding, :user
  
  def initialize(holding:, user:)
    @holding = holding
    @user = user
  end
  
  # Format cost basis
  def formatted_cost_basis
    Money.new(amount: holding.total_cost_basis, currency: user_currency).formatted
  end
  
  # Format current value
  def formatted_current_value
    Money.new(amount: holding.current_value, currency: user_currency).formatted
  end
  
  # Format shares
  def formatted_shares
    "#{holding.shares || 0}"
  end
  
  # Format ticker
  def formatted_ticker
    holding.ticker || 'N/A'
  end
  
  # Format name
  def formatted_name
    holding.name || holding.ticker || 'Unnamed'
  end
  
  private
  
  def user_currency
    user.currency || 'USD'
  end
end

