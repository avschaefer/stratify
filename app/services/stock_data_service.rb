class StockDataService
  require 'net/http'
  require 'date'

  def self.fetch_nasdaq_data(days = 365)
    fetch_index_data('IXIC', days)
  end

  def self.fetch_sp500_data(days = 365)
    fetch_index_data('GSPC', days)
  end

  private

  def self.fetch_index_data(symbol, days)
    # Try Yahoo Finance first
    data = fetch_yahoo_data(symbol, days)
    return data if data && data.length > 0
    
    # Fallback to generated data if API fails
    Rails.logger.warn("Failed to fetch #{symbol}, using fallback data")
    generate_fallback_data(days)
  end

  def self.fetch_yahoo_data(symbol, days)
    begin
      end_date = Date.today
      start_date = end_date - days.days
      
      period1 = start_date.to_time.to_i
      period2 = end_date.to_time.to_i
      
      url = "https://query1.finance.yahoo.com/v7/finance/download/^#{symbol}?period1=#{period1}&period2=#{period2}&interval=1d&events=history"
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 5
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = 'Mozilla/5.0'
      
      response = http.request(request)
      
      if response.code == '200'
        parse_yahoo_csv(response.body, days)
      else
        nil
      end
    rescue => e
      Rails.logger.error("Yahoo Finance error: #{e.message}")
      nil
    end
  end

  def self.parse_yahoo_csv(csv_data, days)
    lines = csv_data.split("\n")
    values = []
    
    lines[1..-1].each do |line|
      next if line.strip.empty?
      parts = line.split(',')
      next if parts.length < 5
      
      begin
        close = parts[4].to_f
        values << close if close > 0
      rescue
        next
      end
    end
    
    if values.length > 0
      values.reverse!
      values
    else
      nil
    end
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

