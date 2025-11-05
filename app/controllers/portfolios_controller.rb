class PortfoliosController < ApplicationController
  def index
    # Mock portfolio data for UI display
    @portfolios = [
      OpenStruct.new(
        ticker: 'AAPL',
        company: 'Apple Inc.',
        asset_type: 'stock',
        purchase_date: Date.parse('2023-01-15'),
        purchase_price: 185.50,
        quantity: 100,
        total_value: 18550.00,
        current_price: 210.50
      ),
      OpenStruct.new(
        ticker: 'TSLA',
        company: 'Tesla Inc.',
        asset_type: 'stock',
        purchase_date: Date.parse('2023-03-20'),
        purchase_price: 245.30,
        quantity: 50,
        total_value: 12265.00,
        current_price: 250.20
      ),
      OpenStruct.new(
        ticker: 'BRK.B',
        company: 'Berkshire Hathaway',
        asset_type: 'stock',
        purchase_date: Date.parse('2023-02-10'),
        purchase_price: 312.00,
        quantity: 40,
        total_value: 12480.00,
        current_price: 305.50
      ),
      OpenStruct.new(
        ticker: 'VOO',
        company: 'Vanguard S&P 500',
        asset_type: 'etf',
        purchase_date: Date.parse('2023-01-05'),
        purchase_price: 385.20,
        quantity: 60,
        total_value: 23112.00,
        current_price: 415.30
      ),
      OpenStruct.new(
        ticker: 'BND',
        company: 'Vanguard Bonds',
        asset_type: 'bond_etf',
        purchase_date: Date.parse('2023-04-12'),
        purchase_price: 78.50,
        quantity: 200,
        total_value: 15700.00,
        current_price: 79.20
      )
    ]
    
    @portfolio = Portfolio.new(user: current_user)
    
    # Calculate summary statistics for metrics tiles
    @portfolio_value = 487500.00
    @total_return_amount = 67500.00
    @total_return_percent = 16.05
    
    # Annual return (assuming 1 year)
    @annual_return_amount = 67500.00
    @annual_return_percent = 16.05
    
    # Comparison with benchmarks
    @nasdaq_return = 12.8
    @sp500_return = 14.2
    @vs_nasdaq = @total_return_percent - @nasdaq_return # +3.25%
    @vs_sp500 = @total_return_percent - @sp500_return # +1.85%
    
    # Realized gains/losses
    @realized_gains = 34250.00
    @realized_losses = -1250.00
    @realized_net = @realized_gains + @realized_losses # +33000
    @realized_percent = 6.77
    
    # Sharpe ratio (risk-adjusted return)
    @sharpe_ratio = 1.42
    
    # Standard deviation (volatility measure)
    @std_deviation = 12.5
    
    # Transaction history data
    @transactions = [
      OpenStruct.new(
        id: 1,
        date: Date.parse('2024-01-15'),
        type: 'buy',
        ticker: 'AAPL',
        company: 'Apple Inc.',
        quantity: 100,
        price: 185.50,
        total: 18550.00
      ),
      OpenStruct.new(
        id: 2,
        date: Date.parse('2024-01-20'),
        type: 'buy',
        ticker: 'TSLA',
        company: 'Tesla Inc.',
        quantity: 50,
        price: 245.30,
        total: 12265.00
      ),
      OpenStruct.new(
        id: 3,
        date: Date.parse('2024-02-10'),
        type: 'buy',
        ticker: 'BRK.B',
        company: 'Berkshire Hathaway',
        quantity: 40,
        price: 312.00,
        total: 12480.00
      ),
      OpenStruct.new(
        id: 4,
        date: Date.parse('2024-03-05'),
        type: 'sell',
        ticker: 'AAPL',
        company: 'Apple Inc.',
        quantity: 25,
        price: 210.50,
        total: 5262.50
      ),
      OpenStruct.new(
        id: 5,
        date: Date.parse('2024-03-15'),
        type: 'buy',
        ticker: 'VOO',
        company: 'Vanguard S&P 500',
        quantity: 60,
        price: 385.20,
        total: 23112.00
      ),
      OpenStruct.new(
        id: 6,
        date: Date.parse('2024-04-12'),
        type: 'buy',
        ticker: 'BND',
        company: 'Vanguard Bonds',
        quantity: 200,
        price: 78.50,
        total: 15700.00
      )
    ].sort_by { |t| t.date }.reverse
    
    # Chart data for the page is now fetched client-side via /portfolios/chart_data
  end
  
  def create
    redirect_to portfolios_path, notice: 'Investment added successfully.'
  end
  
  def destroy
    redirect_to portfolios_path, notice: 'Investment removed.'
  end

  def chart_data
    base_date = Date.today - 365.days
    daily_dates = (0..364).map { |i| base_date + i.days }
    
    # Fetch NASDAQ and S&P 500 data with fallback
    nasdaq_data = StockDataService.fetch_nasdaq_data(365) || []
    sp500_data = StockDataService.fetch_sp500_data(365) || []
    
    # Ensure we have data
    nasdaq_data = StockDataService.send(:generate_fallback_data, 365) if nasdaq_data.empty?
    sp500_data = StockDataService.send(:generate_fallback_data, 365) if sp500_data.empty?
    
    # Generate portfolio data with realistic compound growth
    current_value = 420000.0
    portfolio_data = daily_dates.map do |date|
      # Compound growth: each day grows slightly with volatility
      daily_growth = 0.0015 + (rand - 0.5) * 0.02
      current_value = current_value * (1 + daily_growth)
      current_value
    end
    
    # Trim to exactly 365 items
    nasdaq_data = nasdaq_data.first(365)
    sp500_data = sp500_data.first(365)
    portfolio_data = portfolio_data.first(365)
    
    # Format for Lightweight Charts: { time: unix_timestamp_seconds, value: number }
    # Time must be Unix timestamp in seconds (not milliseconds)
    chart_data = {
      portfolio: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i, # Unix timestamp in seconds
          value: portfolio_data[idx].round(2) # Round to 2 decimal places
        }
      end,
      nasdaq: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: nasdaq_data[idx].round(2)
        }
      end,
      sp500: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: sp500_data[idx].round(2)
        }
      end
    }
    
    render json: chart_data
  end
end
