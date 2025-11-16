class Holding < ApplicationRecord
  belongs_to :portfolio
  has_many :prices, dependent: :destroy
  has_many :trades, dependent: :destroy
  
  validates :ticker, presence: true
  validates :shares, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :cost_basis_cents, numericality: { only_integer: true }, allow_nil: true
  
  def current_value(current_price_cents = nil)
    return 0 if shares.nil? || shares.zero?
    
    # Use provided price, or fetch from database, or fetch from API
    if current_price_cents
      price_cents = current_price_cents
    else
      latest_price_record = latest_price
      if latest_price_record
        price_cents = latest_price_record.amount_cents
      else
        # If no price in database, try to fetch latest price
        price_data = StockPriceService.fetch_price(ticker)
        if price_data
          # Save the price for future use
          price = prices.find_or_initialize_by(date: price_data[:date])
          price.amount_cents = (price_data[:price] * 100).round
          price.save
          price_cents = price.amount_cents
        else
          price_cents = 0
        end
      end
    end
    
    (shares * price_cents / 100.0).round(2)
  end
  
  def latest_price
    prices.order(date: :desc).first
  end
  
  def last_price_update_date
    latest_price&.date
  end
  
  def total_cost_basis
    return 0 if cost_basis_cents.nil?
    cost_basis_cents / 100.0
  end
end

