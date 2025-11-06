class PortfoliosController < ApplicationController
  def index
    @portfolios = current_user.portfolios.order(created_at: :desc)
    @portfolio = Portfolio.new(user: current_user)
    
    # Calculate summary statistics for metrics tiles based on actual data
    @portfolio_value = @portfolios.map { |p| (p.purchase_price || 0) * (p.quantity || 0) }.sum
    @total_return_amount = 0 # Will be calculated when we have current prices
    @total_return_percent = 0
    @annual_return_amount = 0
    @annual_return_percent = 0
    @realized_net = 0
    @realized_percent = 0
    @vs_sp500 = 0
    @sp500_return = 0
    @vs_nasdaq = 0
    @nasdaq_return = 0
    @sharpe_ratio = 0
    @std_deviation = 0
    
    # Use actual portfolios as transactions for display
    @transactions = @portfolios
  end
  
  def create
    @portfolio = current_user.portfolios.build(portfolio_params)
    if @portfolio.save
      redirect_to portfolios_path, notice: 'Investment added successfully.'
    else
      flash.now[:alert] = 'Error adding investment.'
      render :index
    end
  end
  
  def destroy
    @portfolio = current_user.portfolios.find(params[:id])
    @portfolio.destroy
    redirect_to portfolios_path, notice: 'Investment removed.'
  end
  
  def edit
    @portfolio = current_user.portfolios.find(params[:id])
  end
  
  def update
    @portfolio = current_user.portfolios.find(params[:id])
    if @portfolio.update(portfolio_params)
      redirect_to portfolios_path, notice: 'Investment updated successfully.'
    else
      flash.now[:alert] = 'Error updating investment.'
      render :edit
    end
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
    
    # Generate portfolio data based on user's actual portfolios
    user_portfolios = current_user.portfolios
    current_value = user_portfolios.map { |p| (p.purchase_price || 0) * (p.quantity || 0) }.sum
    portfolio_data = daily_dates.map do |date|
      # Simple growth calculation based on date
      growth_factor = 1 + ((date - base_date).to_f / 365.0) * 0.15
      current_value * growth_factor
    end
    
    # Trim to exactly 365 items
    nasdaq_data = nasdaq_data.first(365)
    sp500_data = sp500_data.first(365)
    portfolio_data = portfolio_data.first(365)
    
    # Format for Lightweight Charts: { time: unix_timestamp_seconds, value: number }
    chart_data = {
      portfolio: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: portfolio_data[idx].round(2)
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
  
  private
  
  def portfolio_params
    params.require(:portfolio).permit(:asset_type, :ticker, :purchase_date, :purchase_price, :quantity, :status)
  end
end
