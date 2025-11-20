# frozen_string_literal: true

# Service for generating chart data for portfolio performance
class PortfolioChartDataService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate chart data for portfolio over time
  def generate(days: 365)
    base_date = Date.today - days.days
    daily_dates = (0..(days - 1)).map { |i| base_date + i.days }
    
    portfolio = user.portfolio
    return [] unless portfolio
    
    holdings = portfolio.holdings.holdings.includes(:prices)
    return [] if holdings.empty?
    
    daily_dates.map do |date|
      total_value = holdings.sum do |holding|
        entry_date = holding.entry_date || holding.created_at.to_date
        next 0 if date < entry_date
        
        price_record = holding.prices.where("date <= ?", date).order(date: :desc).first
        price = if price_record
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
        holding.shares * price
      end
      
      {
        time: date.to_time.to_i,
        value: total_value.round(2)
      }
    end
  end
  
  # Generate asset allocation data
  def asset_allocation_data
    portfolio_service = PortfolioValueService.new(user: user)
    allocation = portfolio_service.allocation_percentages
    
    allocation.map do |ticker, percentage|
      {
        label: ticker.humanize,
        value: percentage,
        amount: portfolio_service.value_by_ticker(ticker)
      }
    end
  end
end

