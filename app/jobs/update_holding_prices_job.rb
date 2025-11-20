# frozen_string_literal: true

# Background job to update stock prices for all holdings in a portfolio
class UpdateHoldingPricesJob < ApplicationJob
  queue_as :default

  def perform(portfolio_id)
    portfolio = Portfolio.find_by(id: portfolio_id)
    return unless portfolio

    # Update prices for all holdings (including trades)
    holdings = portfolio.holdings.where.not(ticker: [nil, ''])
    return if holdings.empty?

    holdings.each do |holding|
      update_holding_prices(holding)
    end
  end

  private

  def update_holding_prices(holding)
    return if holding.ticker.blank?

    # Fetch latest price (last 30 days to ensure we get recent data)
    prices_data = StockPriceService.fetch_daily_prices(holding.ticker, 30)
    return unless prices_data&.any?

    # Update or create Price records
    prices_data.each do |price_data|
      price = holding.prices.find_or_initialize_by(date: price_data[:date])
      price.amount_cents = (price_data[:price] * 100).round
      
      unless price.save
        Rails.logger.error("Failed to save price for #{holding.ticker} on #{price_data[:date]}: #{price.errors.full_messages.join(', ')}")
      end
    end

    Rails.logger.info("Updated #{prices_data.length} prices for #{holding.ticker}")
  rescue => e
    Rails.logger.error("Error updating prices for #{holding.ticker}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end

