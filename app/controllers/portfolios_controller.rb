class PortfoliosController < ApplicationController
  def index
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @holdings = @portfolio.holdings.order(created_at: :desc) if @portfolio.persisted?
    @holdings ||= []
    
    # Get all holdings (for Holdings section - combined portfolio)
    @all_holdings = @portfolio.persisted? ? @portfolio.holdings.order(:ticker) : []
    
    # Get only trades for Trade History section
    @trades = @portfolio.persisted? ? @portfolio.holdings.trades.order(entry_date: :desc, created_at: :desc) : []
    
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
    
    # Calculate yearly rollup - YTD for current year, frozen for past years
    @yearly_rollup = []
    if @holdings.any?
      current_year = Date.today.year
      current_date = Date.today
      
      # Get all years from first holding to current year
      first_year = @holdings.map { |h| (h.entry_date || h.created_at.to_date).year }.min || current_year
      years = (first_year..current_year).to_a
      
      years.each do |year|
        year_start = Date.new(year, 1, 1)
        year_end = Date.new(year, 12, 31)
        
        # For current year, use today's date; for past years, use year end
        calculation_date = year == current_year ? current_date : year_end
        
        # Get holdings entered on or before the calculation date
        holdings_in_year = @holdings.select do |h|
          entry_date = h.entry_date || h.created_at.to_date
          entry_date <= calculation_date
        end
        
        # Calculate end of period value
        # For current year (YTD), use current portfolio value
        # For past years, would need historical prices (placeholder for now)
        if year == current_year
          end_value = @portfolio_value
        else
          # For past years, use current value as placeholder
          # TODO: Implement historical price lookup
          end_value = @portfolio_value
        end
        
        # Calculate total cost basis for holdings entered by this date
        total_cost = holdings_in_year.sum(&:total_cost_basis)
        total_return = end_value - total_cost
        total_return_pct = total_cost > 0 ? (total_return / total_cost * 100) : 0
        
        # Calculate realized gain/loss (simplified - would need trade history)
        realized_gain_loss = 0.0
        
        @yearly_rollup << {
          year: year,
          end_value: end_value,
          total_return: total_return,
          total_return_pct: total_return_pct,
          realized_gain_loss: realized_gain_loss,
          is_current_year: year == current_year
        }
      end
    end
  end
  
  def create
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @portfolio.save if @portfolio.new_record?
    
    # Set entry_type and entry_date
    entry_type = params[:entry_type] || 'holding'
    trade_type = params[:holding][:trade_type] if params[:holding]
    
    if entry_type == 'trade' && trade_type == 'sell'
      # Handle sell trade - update existing holding
      result = process_sell_trade(@portfolio, holding_params)
      if result[:success]
        redirect_to portfolios_path, notice: 'Sell trade processed successfully.'
      else
        flash.now[:alert] = result[:error]
        @holdings = @portfolio.holdings.order(created_at: :desc)
        @holdings ||= []
        @all_holdings = @portfolio.holdings.order(:ticker)
        @trades = @portfolio.holdings.trades.order(entry_date: :desc, created_at: :desc)
        @holding = Holding.new(portfolio: @portfolio)
        render :index
      end
    else
      # Handle buy trade or holding - create/update holding
      result = process_buy_trade_or_holding(@portfolio, holding_params, entry_type, trade_type)
      if result[:success]
        entry_type_name = entry_type == 'trade' ? 'Trade' : 'Holding'
        redirect_to portfolios_path, notice: "#{entry_type_name} added successfully."
      else
        flash.now[:alert] = result[:error]
        @holdings = @portfolio.holdings.order(created_at: :desc)
        @holdings ||= []
        @all_holdings = @portfolio.holdings.order(:ticker)
        @trades = @portfolio.holdings.trades.order(entry_date: :desc, created_at: :desc)
        @holding = Holding.new(portfolio: @portfolio)
        render :index
      end
    end
  end
  
  private
  
  def process_sell_trade(portfolio, params_hash)
    ticker = params_hash[:ticker]
    shares_to_sell = params_hash[:shares].to_f
    entry_date = params_hash[:entry_date]
    entry_date = Date.parse(entry_date) if entry_date.is_a?(String)
    entry_date ||= Date.today
    
    # Normalize ticker for search (same logic as Holding model)
    normalized_ticker = normalize_ticker_for_search(ticker)
    
    # Find existing holding
    existing_holding = portfolio.holdings.holdings.find_by(ticker: normalized_ticker)
    
    unless existing_holding
      return { success: false, error: "No existing holding found for #{ticker}. You can only sell shares you already own." }
    end
    
    if existing_holding.shares.to_f < shares_to_sell
      return { success: false, error: "Insufficient shares. You only have #{existing_holding.shares} shares of #{ticker}." }
    end
    
    # Calculate average cost for the sold shares (using existing holding's average cost)
    avg_cost = existing_holding.average_cost
    cost_basis_sold_cents = (shares_to_sell * avg_cost * 100).round
    
    # Create trade record for history
    trade_holding = portfolio.holdings.build(
      ticker: ticker,
      name: existing_holding.name,
      shares: shares_to_sell,
      cost_basis_cents: cost_basis_sold_cents,
      entry_type: 'trade',
      entry_date: entry_date,
      trade_type: 'sell'
    )
    
    unless trade_holding.save
      return { success: false, error: "Error creating trade record: " + trade_holding.errors.full_messages.join(', ') }
    end
    
    # Update existing holding: reduce shares and cost basis proportionally
    remaining_shares = existing_holding.shares.to_f - shares_to_sell
    remaining_cost_basis_cents = existing_holding.cost_basis_cents - cost_basis_sold_cents
    
    if remaining_shares <= 0
      # If selling all shares, delete the holding
      existing_holding.destroy
    else
      existing_holding.update(
        shares: remaining_shares,
        cost_basis_cents: remaining_cost_basis_cents
      )
    end
    
    { success: true }
  end
  
  def process_buy_trade_or_holding(portfolio, params_hash, entry_type, trade_type)
    ticker = params_hash[:ticker]
    shares_to_add = params_hash[:shares].to_f
    avg_cost = params_hash[:average_cost].to_f
    entry_date = params_hash[:entry_date]
    entry_date = Date.parse(entry_date) if entry_date.is_a?(String)
    entry_date ||= Date.today
    cost_basis_cents = (shares_to_add * avg_cost * 100).round
    
    # Normalize ticker for search (same logic as Holding model)
    normalized_ticker = normalize_ticker_for_search(ticker)
    
    # Find existing holding (for buy trades, we merge with existing holdings)
    existing_holding = portfolio.holdings.holdings.find_by(ticker: normalized_ticker)
    
    if existing_holding && entry_type == 'trade'
      # Buy trade: merge with existing holding using weighted average
      existing_shares = existing_holding.shares.to_f
      existing_cost_basis_cents = existing_holding.cost_basis_cents || 0
      
      # Calculate weighted average cost
      total_shares = existing_shares + shares_to_add
      total_cost_basis_cents = existing_cost_basis_cents + cost_basis_cents
      
      existing_holding.update(
        shares: total_shares,
        cost_basis_cents: total_cost_basis_cents
      )
      
      # Create trade record for history
      trade_holding = portfolio.holdings.build(
        ticker: ticker,
        name: existing_holding.name || params_hash[:name],
        shares: shares_to_add,
        cost_basis_cents: cost_basis_cents,
        entry_type: 'trade',
        entry_date: entry_date,
        trade_type: 'buy'
      )
      
      unless trade_holding.save
        return { success: false, error: "Error creating trade record: " + trade_holding.errors.full_messages.join(', ') }
      end
    else
      # New holding or new buy trade (no existing holding)
      @holding = portfolio.holdings.build(params_hash.except(:average_cost))
      @holding.entry_type = entry_type
      @holding.entry_date = entry_date
      @holding.trade_type = trade_type if entry_type == 'trade'
      @holding.cost_basis_cents = cost_basis_cents
      
      unless @holding.save
        return { success: false, error: "Error adding #{entry_type}: " + @holding.errors.full_messages.join(', ') }
      end
    end
    
    { success: true }
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
    if @holding
      # Calculate cost_basis_cents from average_cost if provided
      params_hash = holding_params
      if params_hash[:average_cost] && params_hash[:shares]
        average_cost = params_hash.delete(:average_cost).to_f
        shares = params_hash[:shares].to_f
        params_hash[:cost_basis_cents] = (average_cost * shares * 100).round
      end
      
      if @holding.update(params_hash)
        redirect_to portfolios_path, notice: 'Holding updated successfully.'
      else
        flash.now[:alert] = 'Error updating holding: ' + @holding.errors.full_messages.join(', ')
        render :edit
      end
    else
      redirect_to portfolios_path, alert: 'Holding not found.'
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
    portfolio = current_user.portfolio
    return render json: { portfolio: [] } unless portfolio
    
    # Get all holdings
    holdings = portfolio.holdings.includes(:prices)
    return render json: { portfolio: [] } if holdings.empty?
    
    # Find first entry date
    first_holding = holdings.order(:entry_date, :created_at).first
    if first_holding && first_holding.entry_date
      base_date = [first_holding.entry_date, Date.today - 365.days].min
    elsif first_holding
      base_date = [first_holding.created_at.to_date, Date.today - 365.days].min
    else
      base_date = Date.today - 365.days
    end
    
    # Generate daily dates from base_date to today
    days_diff = (Date.today - base_date).to_i
    daily_dates = (0..days_diff).map { |i| base_date + i.days }
    
    # Calculate portfolio value for each date
    portfolio_data = daily_dates.map do |date|
      total_value = 0.0
      
      holdings.each do |holding|
        # Only include holdings that were entered on or before this date
        holding_entry_date = holding.entry_date || holding.created_at.to_date
        next if date < holding_entry_date
        
        # Get price for this date (closest available price on or before date)
        price_record = holding.prices.where("date <= ?", date).order(date: :desc).first
        
        if price_record
          # Use stored price
          price_cents = price_record.amount_cents
        else
          # Try to fetch current price (fallback - ideally should fetch historical)
          price_data = StockPriceService.fetch_price(holding.ticker, date)
          if price_data
            price_cents = (price_data[:price] * 100).round
            # Save for future use
            holding.prices.find_or_create_by(date: price_data[:date]) do |p|
              p.amount_cents = price_cents
            end
          else
            # Use latest available price or cost basis as fallback
            latest_price = holding.prices.order(date: :desc).first
            price_cents = latest_price&.amount_cents || holding.cost_basis_cents || 0
          end
        end
        
        # Calculate value: shares * price
        if holding.shares && price_cents > 0
          total_value += (holding.shares * price_cents / 100.0)
        end
      end
      
      total_value.round(2)
    end
    
    # Format for Lightweight Charts: { time: unix_timestamp_seconds, value: number }
    chart_data = {
      portfolio: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: portfolio_data[idx]
        }
      end
    }
    
    render json: chart_data
  end
  
  private
  
  def normalize_ticker_for_search(ticker)
    return ticker if ticker.blank?
    return ticker if ticker.include?('/')
    
    ticker_upper = ticker.upcase.strip
    crypto_tickers = %w[
      BTC ETH BNB SOL ADA XRP DOGE DOT AVAX MATIC LTC UNI LINK ATOM ETC XLM
      ALGO VET FIL TRX EOS THETA AAVE COMP MKR SNX YFI SUSHI CRV 1INCH ENJ
      SAND MANA AXS CHZ FLOW ICP NEAR FTM HBAR QNT BAT ZRX OMG GRT REN ZEC
      DASH XMR WAVES ZIL ONT QTUM IOST NEO GAS VTHO CELO CEL
    ]
    
    if crypto_tickers.include?(ticker_upper)
      "#{ticker_upper}/USD"
    else
      ticker_upper
    end
  end
  
  def holding_params
    # Accept frontend-friendly names - average_cost in dollars, convert to cost_basis_cents
    params_hash = params.require(:holding).permit(:ticker, :name, :shares, :average_cost, :index_weight, :entry_date, :trade_type)
    
    # Don't calculate cost_basis_cents here - let the process methods handle it
    # This allows for different handling of buy vs sell trades
    
    params_hash
  end
end
