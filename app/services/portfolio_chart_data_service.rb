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
    
    portfolio_service = PortfolioValueService.new(user: user)
    current_value = portfolio_service.total_value
    
    # For now, use current portfolio value as proxy
    # In a real app, would track historical prices
    daily_dates.map do |date|
      {
        time: date.to_time.to_i,
        value: current_value.round(2)
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

