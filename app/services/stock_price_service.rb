# frozen_string_literal: true

# Service for fetching daily stock prices for individual tickers
class StockPriceService
  require 'net/http'
  require 'date'

  # Fetch price for a specific ticker on a specific date
  # Returns { date: Date, price: Float } or nil
  def self.fetch_price(ticker, date = Date.today)
    # Fetch last 7 days to ensure we get data around the requested date
    prices = fetch_daily_prices(ticker, 7, date)
    return nil unless prices&.any?
    
    # Find the price closest to the requested date (on or before)
    prices.select { |p| p[:date] <= date }.max_by { |p| p[:date] } || prices.first
  end

  # Fetch historical daily prices for a ticker
  # Returns array of { date: Date, price: Float } hashes
  def self.fetch_daily_prices(ticker, days = 365, end_date = Date.today)
    return nil if ticker.blank?
    
    begin
      start_date = end_date - days.days
      period1 = start_date.to_time.to_i
      period2 = end_date.to_time.to_i
      
      # Yahoo Finance CSV endpoint
      url = "https://query1.finance.yahoo.com/v7/finance/download/#{ticker.upcase}?period1=#{period1}&period2=#{period2}&interval=1d&events=history"
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      
      response = http.request(request)
      
      if response.code == '200'
        parse_yahoo_csv(response.body)
      else
        Rails.logger.warn("Failed to fetch price for #{ticker}: HTTP #{response.code}")
        nil
      end
    rescue => e
      Rails.logger.error("Error fetching price for #{ticker}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end
  end

  private

  def self.parse_yahoo_csv(csv_data)
    lines = csv_data.split("\n")
    return nil if lines.length < 2
    
    prices = []
    
    # Skip header line
    lines[1..-1].each do |line|
      next if line.strip.empty?
      parts = line.split(',')
      next if parts.length < 5
      
      begin
        date_str = parts[0]
        close_price = parts[4].to_f
        
        next if close_price <= 0
        
        date = Date.parse(date_str)
        prices << { date: date, price: close_price }
      rescue => e
        Rails.logger.debug("Error parsing CSV line: #{line} - #{e.message}")
        next
      end
    end
    
    # Return prices sorted by date (oldest first)
    prices.sort_by { |p| p[:date] }
  end
end

