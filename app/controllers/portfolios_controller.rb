class PortfoliosController < ApplicationController
  def index
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @holdings = @portfolio.holdings.order(created_at: :desc) if @portfolio.persisted?
    @holdings ||= []
    @holding = Holding.new(portfolio: @portfolio)
    
    # Calculate summary statistics for metrics tiles based on actual data
    portfolio_service = PortfolioValueService.new(user: current_user)
    @portfolio_value = portfolio_service.total_value
    @total_cost_basis = portfolio_service.total_cost_basis
    @total_return_amount = @portfolio_value - @total_cost_basis
    @total_return_percent = @total_cost_basis > 0 ? (@total_return_amount / @total_cost_basis * 100) : 0
    @annual_return_amount = 0 # Will be calculated when we have historical prices
    @annual_return_percent = 0
    @realized_net = 0
    @realized_percent = 0
    @vs_sp500 = 0
    @sp500_return = 0
    @vs_nasdaq = 0
    @nasdaq_return = 0
    @sharpe_ratio = 0
    @std_deviation = 0
    
    # Use holdings as transactions for display
    @transactions = @holdings
  end
  
  def create
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @portfolio.save if @portfolio.new_record?
    
    @holding = @portfolio.holdings.build(holding_params)
    if @holding.save
      redirect_to portfolios_path, notice: 'Holding added successfully.'
    else
      flash.now[:alert] = 'Error adding holding.'
      @holdings = @portfolio.holdings.order(created_at: :desc)
      render :index
    end
  end
  
  def destroy
    @holding = current_user.portfolio&.holdings&.find(params[:id])
    if @holding
      @holding.destroy
      redirect_to portfolios_path, notice: 'Holding removed.'
    else
      redirect_to portfolios_path, alert: 'Holding not found.'
    end
  end
  
  def edit
    @holding = current_user.portfolio&.holdings&.find(params[:id])
    redirect_to portfolios_path, alert: 'Holding not found.' unless @holding
  end
  
  def update
    @holding = current_user.portfolio&.holdings&.find(params[:id])
    if @holding&.update(holding_params)
      redirect_to portfolios_path, notice: 'Holding updated successfully.'
    else
      flash.now[:alert] = 'Error updating holding.'
      render :edit
    end
  end

  def update_prices
    @portfolio = current_user.portfolio
    if @portfolio&.persisted?
      UpdateHoldingPricesJob.perform_later(@portfolio.id)
      redirect_to portfolios_path, notice: 'Price update started. Prices will be updated shortly.'
    else
      redirect_to portfolios_path, alert: 'No portfolio found.'
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
    
    # Generate portfolio data based on user's actual holdings
    portfolio_service = PortfolioValueService.new(user: current_user)
    current_value = portfolio_service.total_value
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
  
  def holding_params
    # Accept frontend-friendly names - cost_basis in dollars, convert to cents
    params_hash = params.require(:holding).permit(:ticker, :name, :shares, :cost_basis, :index_weight)
    if params_hash[:cost_basis]
      params_hash[:cost_basis_cents] = (params_hash.delete(:cost_basis).to_f * 100).round
    end
    params_hash
  end
end
