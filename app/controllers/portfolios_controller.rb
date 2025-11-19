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
    
    # Calculate index comparison data (3, 6, 12 month returns)
    # For now, using placeholder calculations - will be replaced with actual historical data
    @portfolio_3m = 0.0
    @portfolio_6m = 0.0
    @portfolio_12m = 0.0
    @sp500_3m = 0.0
    @sp500_6m = 0.0
    @sp500_12m = 0.0
    @nasdaq_3m = 0.0
    @nasdaq_6m = 0.0
    @nasdaq_12m = 0.0
    
    # Calculate yearly rollup
    @yearly_rollup = []
    if @holdings.any?
      # Group holdings by year
      years = @holdings.map { |h| h.created_at.year }.uniq.sort
      years.each do |year|
        year_start = Date.new(year, 1, 1)
        year_end = Date.new(year, 12, 31)
        
        # Get holdings created in this year or earlier
        holdings_in_year = @holdings.select { |h| h.created_at.year <= year }
        
        # Calculate end of year value (simplified - would need historical prices)
        end_value = @portfolio_value # Placeholder - should use historical prices
        
        # Calculate total return (simplified)
        total_cost = holdings_in_year.sum(&:total_cost_basis) / 100.0
        total_return = end_value - total_cost
        total_return_pct = total_cost > 0 ? (total_return / total_cost * 100) : 0
        
        # Calculate realized gain/loss (simplified - would need trade history)
        realized_gain_loss = 0.0
        
        @yearly_rollup << {
          year: year,
          end_value: end_value,
          total_return: total_return,
          total_return_pct: total_return_pct,
          realized_gain_loss: realized_gain_loss
        }
      end
    end
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
    # Find first user input (first holding date)
    first_holding = current_user.portfolio&.holdings&.order(:created_at)&.first
    if first_holding
      base_date = [first_holding.created_at.to_date, Date.today - 365.days].min
    else
      base_date = Date.today - 365.days
    end
    
    # Generate daily dates from base_date to today
    days_diff = (Date.today - base_date).to_i
    daily_dates = (0..days_diff).map { |i| base_date + i.days }
    
    # Fetch NASDAQ and S&P 500 data with fallback
    nasdaq_data = StockDataService.fetch_nasdaq_data(days_diff + 1) || []
    sp500_data = StockDataService.fetch_sp500_data(days_diff + 1) || []
    
    # Ensure we have data
    nasdaq_data = StockDataService.send(:generate_fallback_data, days_diff + 1) if nasdaq_data.empty?
    sp500_data = StockDataService.send(:generate_fallback_data, days_diff + 1) if sp500_data.empty?
    
    # Generate portfolio data based on user's actual holdings
    portfolio_service = PortfolioValueService.new(user: current_user)
    current_value = portfolio_service.total_value
    
    # Calculate portfolio value over time (simplified - would need historical prices)
    portfolio_data = daily_dates.map do |date|
      if first_holding && date >= first_holding.created_at.to_date
        # Simple growth calculation from first holding date
        days_since_first = (date - first_holding.created_at.to_date).to_i
        total_days = (Date.today - first_holding.created_at.to_date).to_i
        if total_days > 0
          growth_factor = 1 + (days_since_first.to_f / total_days) * 0.15
          current_value * growth_factor
        else
          current_value
        end
      else
        # Before first holding, use initial value
        portfolio_service.total_cost_basis / 100.0
      end
    end
    
    # Trim to match date range
    nasdaq_data = nasdaq_data.first(daily_dates.length)
    sp500_data = sp500_data.first(daily_dates.length)
    portfolio_data = portfolio_data.first(daily_dates.length)
    
    # Format for Lightweight Charts: { time: unix_timestamp_seconds, value: number }
    chart_data = {
      portfolio: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: portfolio_data[idx].round(2)
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
