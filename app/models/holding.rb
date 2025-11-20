class Holding < ApplicationRecord
  belongs_to :portfolio
  has_many :prices, dependent: :destroy
  has_many :trades, dependent: :destroy
  
  validates :ticker, presence: true
  validates :shares, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :cost_basis_cents, numericality: { only_integer: true }, allow_nil: true
  validates :entry_type, inclusion: { in: %w[holding trade] }
  validates :entry_date, presence: true
  validates :trade_type, inclusion: { in: %w[buy sell] }, allow_nil: true
  
  scope :holdings, -> { where(entry_type: 'holding') }
  scope :trades, -> { where(entry_type: 'trade') }
  scope :by_entry_date, -> { order(entry_date: :desc, created_at: :desc) }
  scope :buy_trades, -> { where(trade_type: 'buy') }
  scope :sell_trades, -> { where(trade_type: 'sell') }
  
  before_save :normalize_ticker
  
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
  
  def average_cost
    return 0 if shares.nil? || shares.zero? || cost_basis_cents.nil?
    (cost_basis_cents / 100.0) / shares
  end
  
  def unrealized_return
    current_value - total_cost_basis
  end
  
  def unrealized_return_percent
    return 0 if total_cost_basis.zero?
    (unrealized_return / total_cost_basis * 100)
  end
  
  def todays_return
    return 0 if shares.nil? || shares.zero?
    
    # Get yesterday's price and today's price
    today_price = latest_price
    return 0 unless today_price
    
    yesterday_date = today_price.date - 1.day
    yesterday_price = prices.where("date <= ?", yesterday_date).order(date: :desc).first
    
    return 0 unless yesterday_price
    
    price_change = (today_price.amount_cents - yesterday_price.amount_cents) / 100.0
    shares * price_change
  end
  
  def todays_return_percent
    return 0 if shares.nil? || shares.zero?
    
    today_price = latest_price
    return 0 unless today_price
    
    yesterday_date = today_price.date - 1.day
    yesterday_price = prices.where("date <= ?", yesterday_date).order(date: :desc).first
    
    return 0 unless yesterday_price
    
    price_change = (today_price.amount_cents - yesterday_price.amount_cents) / 100.0
    yesterday_price_value = yesterday_price.amount_cents / 100.0
    return 0 if yesterday_price_value.zero?
    
    (price_change / yesterday_price_value * 100)
  end
  
  private
  
  def normalize_ticker
    return if ticker.blank?
    
    # Normalize crypto tickers to BASE/USD format
    # If already has slash, assume it's correct
    return if ticker.include?('/')
    
    ticker_upper = ticker.upcase.strip
    
    # Common crypto tickers
    crypto_tickers = %w[
      BTC ETH BNB SOL ADA XRP DOGE DOT AVAX MATIC LTC UNI LINK ATOM ETC XLM 
      ALGO VET FIL TRX EOS THETA AAVE COMP MKR SNX YFI SUSHI CRV 1INCH ENJ 
      SAND MANA AXS CHZ FLOW ICP NEAR FTM HBAR QNT BAT ZRX OMG GRT REN ZEC 
      DASH XMR WAVES ZIL ONT QTUM IOST NEO GAS VTHO CELO CEL
    ]
    
    # If it's a known crypto ticker, convert to BASE/USD format
    if crypto_tickers.include?(ticker_upper)
      self.ticker = "#{ticker_upper}/USD"
    else
      # For stocks, just uppercase
      self.ticker = ticker_upper
    end
  end
end

