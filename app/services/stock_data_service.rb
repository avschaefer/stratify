# frozen_string_literal: true

# Service for fetching index data (NASDAQ, S&P 500) using TwelveData API
class StockDataService
  require 'net/http'
  require 'json'
  require 'date'
  require 'uri'

  BASE_URL = 'https://api.twelvedata.com/time_series'

  def self.fetch_nasdaq_data(days = 365)
    fetch_index_data('IXIC', days)
  end

  def self.fetch_sp500_data(days = 365)
    fetch_index_data('SPX', days)
  end

  private

  def self.fetch_index_data(symbol, days)
    # Try TwelveData API first
    data = fetch_twelvedata_index(symbol, days)
    return data if data && data.length > 0
    
    # Fallback to generated data if API fails
    Rails.logger.warn("Failed to fetch #{symbol}, using fallback data")
    generate_fallback_data(days)
  end

  def self.fetch_twelvedata_index(symbol, days)
    api_key = ENV['TWELVEDATA_API_KEY']
    if api_key.blank?
      Rails.logger.error("TWELVEDATA_API_KEY is not set in environment variables")
      return nil
    end

    begin
      end_date = Date.today
      start_date = end_date - days.days
      
      # Format dates for TwelveData API (YYYY-MM-DD)
      start_date_str = start_date.strftime('%Y-%m-%d')
      end_date_str = end_date.strftime('%Y-%m-%d')
      
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
        Rails.logger.warn("Failed to fetch #{symbol}: HTTP #{response.code} - #{response.body}")
        nil
      end
    rescue => e
      Rails.logger.error("TwelveData API error for #{symbol}: #{e.message}")
      nil
    end
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
    
    values = []
    
    data['values'].each do |entry|
      begin
        close_price = entry['close'].to_f
        values << close_price if close_price > 0
      rescue => e
        Rails.logger.debug("Error parsing TwelveData entry: #{entry.inspect} - #{e.message}")
        next
      end
    end
    
    # Return values in chronological order (oldest first)
    # TwelveData returns newest first, so we reverse
    values.reverse!
    values
  end

  def self.generate_fallback_data(days)
    base_value = 12000.0
    data = []
    
    (0..days).each do |i|
      daily_change = (rand - 0.5) * 0.02
      base_value *= (1 + daily_change)
      data << base_value
    end
    
    data
  end
end

