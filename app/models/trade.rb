class Trade < ApplicationRecord
  belongs_to :holding, optional: true  # Optional for cash trades
  
  validates :trade_date, presence: true
  validates :trade_type, presence: true
  
  enum :trade_type, { buy: 0, sell: 1 }
  
  scope :by_date, -> { order(trade_date: :desc) }
end

