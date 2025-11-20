class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :holdings, dependent: :destroy
  
  validates :user_id, uniqueness: true  # has_one relationship
  
  def total_value
    # Only sum holdings (not trades) for portfolio value
    holdings.holdings.sum { |h| h.current_value }
  end
  
  def total_cost_basis
    # Only sum holdings (not trades) for cost basis
    holdings.holdings.sum { |h| h.total_cost_basis }
  end
  
  def realized_pnl
    # Calculate realized P&L from sell trades
    sell_trades = holdings.sell_trades
    return 0 if sell_trades.empty?
    
    # For each sell trade, calculate gain/loss
    # This is simplified - assumes FIFO cost basis
    sell_trades.sum do |trade|
      # Get the average cost from the trade's cost_basis_cents
      avg_cost = trade.average_cost
      current_price = trade.latest_price&.amount_cents ? (trade.latest_price.amount_cents / 100.0) : avg_cost
      
      # Realized gain = (sell price - avg cost) * shares
      (current_price - avg_cost) * (trade.shares || 0)
    end
  end
end

