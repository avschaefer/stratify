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
    
    # Only use holdings (not trades) for portfolio calculations
    actual_holdings = @portfolio.persisted? ? @portfolio.holdings.holdings : []
    
    @portfolio_value = actual_holdings.sum { |h| h.current_value }
    @total_cost_basis = actual_holdings.sum { |h| h.total_cost_basis }
    @total_return_amount = @portfolio_value - @total_cost_basis
    @total_return_percent = @total_cost_basis > 0 ? (@total_return_amount / @total_cost_basis * 100) : 0
    
    # Calculate annual return (YTD)
    current_year = Date.today.year
    year_start = Date.new(current_year, 1, 1)
    
    holdings_at_year_start = actual_holdings.select do |h|
      (h.entry_date || h.created_at.to_date) <= year_start
    end
    
    year_start_value = calculate_portfolio_value_at(year_start - 1.day, holdings_at_year_start) # Use day before to avoid including Jan 1 buys if needed
    @annual_return_amount = @portfolio_value - year_start_value
    @annual_return_percent = year_start_value > 0 ? (@annual_return_amount / year_start_value * 100).round(2) : 0
    
    # Calculate realized P&L from sell trades
    sell_trades = @portfolio.persisted? ? @portfolio.holdings.sell_trades : []
    @realized_net = sell_trades.sum do |trade|
      price = get_price_for_holding(trade, trade.entry_date)
      sale_value = trade.shares * price
      sale_value - trade.total_cost_basis
    end
    
    sold_cost_basis = sell_trades.sum { |t| t.total_cost_basis }
    @realized_percent = sold_cost_basis > 0 ? (@realized_net / sold_cost_basis * 100).round(2) : 0
    
    # Calculate index comparisons (vs S&P 500 and NASDAQ)
    @sp500_return = calculate_index_return('SPX', 365)
    @nasdaq_return = calculate_index_return('IXIC', 365)
    
    # Portfolio return for comparison (1 year)
    portfolio_return_1y = calculate_portfolio_return(365)
    
    @vs_sp500 = portfolio_return_1y - @sp500_return
    @vs_nasdaq = portfolio_return_1y - @nasdaq_return
    
    # Calculate Sharpe ratio and standard deviation
    sharpe_data = calculate_sharpe_ratio(actual_holdings)
    @sharpe_ratio = sharpe_data[:sharpe_ratio]
    @std_deviation = sharpe_data[:std_deviation]
    
    # Calculate index comparison data (3, 6, 12 month returns)
    @portfolio_3m = calculate_portfolio_return(90)
    @portfolio_6m = calculate_portfolio_return(180)
    @portfolio_12m = calculate_portfolio_return(365)
    @sp500_3m = calculate_index_return('SPX', 90)
    @sp500_6m = calculate_index_return('SPX', 180)
    @sp500_12m = calculate_index_return('SPX', 365)
    @nasdaq_3m = calculate_index_return('IXIC', 90)
    @nasdaq_6m = calculate_index_return('IXIC', 180)
    @nasdaq_12m = calculate_index_return('IXIC', 365)
    
    # Calculate yearly rollup - YTD for current year, frozen for past years
    @yearly_rollup = []
    if actual_holdings.any?
      current_year = Date.today.year
      current_date = Date.today
      
      # Get all years from first holding to current year
      first_year = actual_holdings.map { |h| (h.entry_date || h.created_at.to_date).year }.min || current_year
      years = (first_year..current_year).to_a
      
      years.each do |year|
        year_start = Date.new(year, 1, 1)
        year_end = Date.new(year, 12, 31)
        
        # For current year, use today's date; for past years, use year end
        calculation_date = year == current_year ? current_date : year_end
        
        # Get holdings entered on or before the calculation date (only holdings, not trades)
        holdings_in_period = actual_holdings.select do |h|
          entry_date = h.entry_date || h.created_at.to_date
          entry_date <= calculation_date
        end
        
        # Calculate end of period value using historical prices
        end_value = calculate_portfolio_value_at(calculation_date, holdings_in_period)
        
        # Calculate total cost basis for holdings entered by this date
        total_cost = holdings_in_period.sum(&:total_cost_basis)
        total_return = end_value - total_cost
        total_return_pct = total_cost > 0 ? (total_return / total_cost * 100).round(2) : 0
        
        # Calculate realized gain/loss from sell trades in this period
        period_start = year_start
        period_end = calculation_date
        sell_trades_in_period = @portfolio.holdings.sell_trades.where("entry_date >= ? AND entry_date <= ?", period_start, period_end)
        realized_gain_loss = sell_trades_in_period.sum do |t|
          price = get_price_for_holding(t, t.entry_date)
          (t.shares * price) - t.total_cost_basis
        end
        
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
  
  def new
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @holding = Holding.new(portfolio: @portfolio)
    @holding.entry_type = params[:entry_type] || 'holding'
    @holding.trade_type = params[:trade_type] || 'buy'
    render :edit
  end

  def create
    @portfolio = current_user.portfolio || current_user.build_portfolio
    @portfolio.save if @portfolio.new_record?
    
    # Set entry_type and entry_date
    entry_type = params[:holding][:entry_type] || 'holding'
    trade_type = params[:holding][:trade_type] if params[:holding]
    
    if entry_type == 'trade' && trade_type == 'sell'
      # Handle sell trade - update existing holding
      result = process_sell_trade(@portfolio, holding_params)
      if result[:success]
        redirect_to portfolios_path, notice: 'Sell trade processed successfully.'
      else
        flash.now[:alert] = result[:error]
        @holding = Holding.new(portfolio: @portfolio)
        render :edit
      end
    else
      # Handle buy trade or holding - create/update holding
      result = process_buy_trade_or_holding(@portfolio, holding_params, entry_type, trade_type)
      if result[:success]
        entry_type_name = entry_type == 'trade' ? 'Trade' : 'Holding'
        redirect_to portfolios_path, notice: "#{entry_type_name} added successfully."
      else
        flash.now[:alert] = result[:error]
        @holding = Holding.new(portfolio: @portfolio)
        render :edit
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
    portfolio = current_user.portfolio
    if portfolio.nil?
      redirect_to portfolios_path, alert: 'No portfolio found.'
      return
    end
    @holding = portfolio.holdings.find_by(id: params[:id]) || Holding.new(portfolio: portfolio)
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
      # Update prices synchronously for immediate feedback
      # Update ALL holdings regardless of entry_type (holdings AND trades)
      holdings = @portfolio.holdings.where.not(ticker: [nil, ''])
      updated_count = 0
      
      # Group by ticker to avoid fetching the same price multiple times
      unique_tickers = holdings.pluck(:ticker).uniq
      
      unique_tickers.each do |ticker|
        begin
          prices_data = StockPriceService.fetch_daily_prices(ticker, 30)
          next unless prices_data&.any?
          
          # Update all holdings with this ticker
          holdings_with_ticker = holdings.where(ticker: ticker)
          
          prices_data.each do |price_data|
            holdings_with_ticker.each do |holding|
              price = holding.prices.find_or_initialize_by(date: price_data[:date])
              price.amount_cents = (price_data[:price] * 100).round
              price.save
            end
          end
          
          updated_count += holdings_with_ticker.count
        rescue => e
          Rails.logger.error("Error updating prices for #{ticker}: #{e.message}")
        end
      end
      
      # Also queue background job for comprehensive update
      UpdateHoldingPricesJob.perform_later(@portfolio.id)
      
      redirect_to portfolios_path, notice: "Price update started. Updated prices for #{updated_count} entries."
    else
      redirect_to portfolios_path, alert: 'No portfolio found.'
    end
  end

  def chart_data
    portfolio = current_user.portfolio
    return render json: { portfolio: [] } unless portfolio
    
    # Get all holdings (both initial holdings and trades) to calculate portfolio value
    holdings = portfolio.holdings.includes(:prices)
    return render json: { portfolio: [] } if holdings.empty?
    
    # Determine date range based on period
    period = params[:period] || 'ALL'
    end_date = Date.today
    
    start_date = case period
                 when '1M' then end_date - 1.month
                 when '3M' then end_date - 3.months
                 when '6M' then end_date - 6.months
                 when '1Y' then end_date - 1.year
                 else
                   # For ALL, find first entry date
                   first_holding = holdings.order(:entry_date, :created_at).first
                   if first_holding && first_holding.entry_date
                     [first_holding.entry_date, end_date - 365.days].min
                   elsif first_holding
                     [first_holding.created_at.to_date, end_date - 365.days].min
                   else
                     end_date - 365.days
                   end
                 end
    
    # Generate daily dates from start_date to today
    days_diff = (end_date - start_date).to_i
    daily_dates = (0..days_diff).map { |i| start_date + i.days }
    
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
    # Filter out zero values at the beginning (before any holdings existed)
    chart_points = daily_dates.map.with_index do |date, idx|
      {
        time: date.to_time.to_i,
        value: portfolio_data[idx]
      }
    end
    
    # Remove leading zeros (before portfolio had any value)
    while chart_points.first && chart_points.first[:value] == 0 && chart_points.length > 1
      chart_points.shift
    end
    
    chart_data = {
      portfolio: chart_points
    }
    
    render json: chart_data
  end
  
  private
  
  def calculate_index_return(symbol, days)
    begin
      index_data = symbol == 'SPX' ? StockDataService.fetch_sp500_data(days) : StockDataService.fetch_nasdaq_data(days)
      return 0 unless index_data && index_data.length >= 2
      
      start_price = index_data.first
      end_price = index_data.last
      return 0 if start_price.nil? || end_price.nil? || start_price.zero?
      
      ((end_price - start_price) / start_price * 100).round(2)
    rescue => e
      Rails.logger.error("Error calculating index return for #{symbol}: #{e.message}")
      0
    end
  end
  
  def calculate_sharpe_ratio(holdings)
    return { sharpe_ratio: 0, std_deviation: 0 } if holdings.empty?
    
    # Need at least 30 days of price data for meaningful calculation
    # Calculate daily returns for the past 90 days (more data = better calculation)
    daily_values = []
    (0..89).each do |days_ago|
      date = Date.today - days_ago.days
      
      # Calculate portfolio value on this date
      portfolio_value = holdings.sum do |holding|
        price = holding.prices.where("date <= ?", date).order(date: :desc).first
        if price
          (holding.shares || 0) * (price.amount_cents / 100.0)
        else
          # If no price data, skip this holding for this date
          nil
        end
      end
      
      # Only add if we have valid data
      daily_values << portfolio_value if portfolio_value && portfolio_value > 0
    end
    
    # Need at least 30 data points
    return { sharpe_ratio: 0, std_deviation: 0 } if daily_values.length < 30
    
    # Reverse to get chronological order (oldest first)
    daily_values.reverse!
    
    # Calculate daily percentage returns
    daily_pct_returns = []
    (1...daily_values.length).each do |i|
      prev_value = daily_values[i - 1]
      curr_value = daily_values[i]
      if prev_value && curr_value && prev_value > 0
        daily_pct_returns << ((curr_value - prev_value) / prev_value * 100)
      end
    end
    
    return { sharpe_ratio: 0, std_deviation: 0 } if daily_pct_returns.empty? || daily_pct_returns.length < 10
    
    # Calculate mean return
    mean_return = daily_pct_returns.sum / daily_pct_returns.length
    
    # Calculate standard deviation (sample standard deviation)
    variance = daily_pct_returns.sum { |r| (r - mean_return) ** 2 } / (daily_pct_returns.length - 1)
    std_deviation = Math.sqrt(variance)
    
    # Annualize returns (assuming 252 trading days)
    annualized_return = mean_return * 252
    annualized_std = std_deviation * Math.sqrt(252)
    
    # Sharpe ratio = (Return - Risk-free rate) / Std Dev
    # Using 0% as risk-free rate for simplicity
    sharpe_ratio = annualized_std > 0 ? (annualized_return / annualized_std) : 0
    
    { sharpe_ratio: sharpe_ratio.round(2), std_deviation: annualized_std.round(2) }
  rescue => e
    Rails.logger.error("Error calculating Sharpe ratio: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { sharpe_ratio: 0, std_deviation: 0 }
  end
  
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

  def get_price_for_holding(holding, date)
    price_record = holding.prices.where("date <= ?", date).order(date: :desc).first
    if price_record
      price_record.amount_cents / 100.0
    else
      price_data = StockPriceService.fetch_price(holding.ticker, date)
      if price_data
        amount = price_data[:price]
        holding.prices.create!(date: price_data[:date], amount_cents: (amount * 100).round)
        amount
      else
        holding.average_cost || 0
      end
    end
  end

  def calculate_portfolio_value_at(date, holdings)
    holdings.sum do |h|
      entry_date = h.entry_date || h.created_at.to_date
      next 0 if entry_date > date
      price = get_price_for_holding(h, date)
      h.shares * price
    end
  end

  def calculate_portfolio_return(days)
    start_date = Date.today - days.days
    start_holdings = @portfolio.holdings.holdings.select { |h| (h.entry_date || h.created_at.to_date) <= start_date }
    start_value = calculate_portfolio_value_at(start_date, start_holdings)
    end_value = @portfolio_value
    start_value > 0 ? ((end_value - start_value) / start_value * 100).round(2) : 0
  end
end
