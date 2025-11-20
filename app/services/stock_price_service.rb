# frozen_string_literal: true

# Service for fetching daily stock prices for individual tickers using TwelveData API
class StockPriceService
  require 'net/http'
  require 'json'
  require 'date'
  require 'uri'

  BASE_URL = 'https://api.twelvedata.com/time_series'

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
    
    api_key = ENV['TWELVEDATA_API_KEY']
    if api_key.blank?
      Rails.logger.error("TWELVEDATA_API_KEY is not set in environment variables")
      return nil
    end
    
    begin
      start_date = end_date - days.days
      
      # Format dates for TwelveData API (YYYY-MM-DD)
      start_date_str = start_date.strftime('%Y-%m-%d')
      end_date_str = end_date.strftime('%Y-%m-%d')
      
      # Normalize ticker symbol (handle crypto pairs like BTC/USD)
      symbol = normalize_symbol(ticker)
      
      # Build query parameters
      params = {
        symbol: symbol,
        interval: '1day',
        apikey: api_key,
        start_date: start_date_str,
        end_date: end_date_str,
        format: 'JSON'
      }
      
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 15
      
      request = Net::HTTP::Get.new(uri.request_uri)
      
      response = http.request(request)
      
      if response.code == '200'
        parse_twelvedata_json(response.body)
      else
        Rails.logger.warn("Failed to fetch price for #{ticker}: HTTP #{response.code} - #{response.body}")
        nil
      end
    rescue => e
      Rails.logger.error("Error fetching price for #{ticker}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end
  end

  private

  # Normalize ticker symbol for TwelveData API
  # Crypto symbols should be in format BASE/QUOTE (e.g., BTC/USD)
  # Stock symbols are used as-is
  def self.normalize_symbol(ticker)
    return nil if ticker.blank?
    
    # If ticker contains a slash, assume it's already in correct format (crypto)
    return ticker.upcase if ticker.include?('/')
    
    ticker_upper = ticker.upcase.strip
    
    # Common crypto tickers (major cryptocurrencies)
    crypto_tickers = %w[
      BTC ETH BNB SOL ADA XRP DOGE DOT AVAX MATIC LTC UNI LINK ATOM ETC XLM 
      ALGO VET FIL TRX EOS THETA AAVE COMP MKR SNX YFI SUSHI CRV 1INCH ENJ 
      SAND MANA AXS CHZ FLOW ICP NEAR FTM HBAR QNT BAT ZRX OMG GRT REN ZEC 
      DASH XMR EOS WAVES ZIL ONT QTUM IOST NEO GAS VTHO CELO CEL
    ]
    
    # If it's a known crypto ticker, convert to BASE/USD format
    if crypto_tickers.include?(ticker_upper)
      return "#{ticker_upper}/USD"
    end
    
    # Check if it looks like a crypto ticker (short, all caps, common patterns)
    # Most crypto tickers are 2-5 characters and don't match stock patterns
    if ticker_upper.length <= 5 && ticker_upper.match?(/\A[A-Z0-9]+\z/) && !ticker_upper.match?(/\A[A-Z]{1,2}\z/)
      # Try as crypto first - if API fails, can fallback to stock
      return "#{ticker_upper}/USD"
    end
    
    # For stocks, use uppercase
    ticker.upcase
  end

  def self.parse_twelvedata_json(json_data)
    data = JSON.parse(json_data)
    
    # Check for API errors
    if data['status'] == 'error'
      Rails.logger.error("TwelveData API error: #{data['message']}")
      return nil
    end
    
    # Check if we have values array
    unless data['values'].is_a?(Array)
      Rails.logger.warn("Unexpected response format from TwelveData API: #{data.keys.inspect}")
      return nil
    end
    
    # Return empty array if no values
    return [] if data['values'].empty?
    
    prices = []
    
    data['values'].each do |entry|
      begin
        # TwelveData returns datetime in format: "2024-01-15 16:00:00"
        datetime_str = entry['datetime']
        close_price = entry['close'].to_f
        
        next if close_price <= 0 || datetime_str.blank?
        
        # Parse date (handle both date-only and datetime formats)
        date = if datetime_str.include?(' ')
          Date.parse(datetime_str.split(' ').first)
        else
          Date.parse(datetime_str)
        end
        
        prices << { date: date, price: close_price }
      rescue => e
        Rails.logger.debug("Error parsing TwelveData entry: #{entry.inspect} - #{e.message}")
        next
      end
    end
    
    # Return prices sorted by date (oldest first)
    prices.sort_by { |p| p[:date] }
  end
end

