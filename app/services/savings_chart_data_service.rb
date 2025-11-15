# frozen_string_literal: true

# Service for generating chart data for savings and spending over time
class SavingsChartDataService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate chart data for the last year
  def generate(days: 365)
    begin
      Rails.logger.info "SavingsChartDataService: Starting data generation for user #{user.id}"
      
      base_date = Date.today - days.days
      daily_dates = (0..(days - 1)).map { |i| base_date + i.days }
      
      Rails.logger.info "SavingsChartDataService: Generated #{daily_dates.length} daily dates from #{base_date} to #{Date.today}"
      
      # Get all balances for savings accounts (savings and checking)
      savings_accounts = user.accounts.where(account_type: ['savings', 'checking']).includes(:balances)
      Rails.logger.info "SavingsChartDataService: Found #{savings_accounts.count} savings/checking accounts"
      
      all_savings_snapshots_raw = savings_accounts.flat_map(&:balances)
      Rails.logger.info "SavingsChartDataService: Found #{all_savings_snapshots_raw.length} raw savings balances"
      
      all_savings_snapshots = all_savings_snapshots_raw
        .compact
        .select { |s| s.balance_date.present? && s.amount_cents.present? }
        .group_by { |s| s.balance_date.beginning_of_month }
      
      Rails.logger.info "SavingsChartDataService: Grouped into #{all_savings_snapshots.keys.length} unique months for savings"
      
      # Get all balances for credit cards (spending/expenses)
      credit_cards = user.accounts.where(account_type: 'credit_card').includes(:balances)
      Rails.logger.info "SavingsChartDataService: Found #{credit_cards.count} credit card accounts"
      
      all_expense_snapshots_raw = credit_cards.flat_map(&:balances)
      Rails.logger.info "SavingsChartDataService: Found #{all_expense_snapshots_raw.length} raw credit card balances"
      
      all_expense_snapshots = all_expense_snapshots_raw
        .compact
        .select { |s| s.balance_date.present? && s.amount_cents.present? }
        .group_by { |s| s.balance_date.beginning_of_month }
      
      Rails.logger.info "SavingsChartDataService: Grouped into #{all_expense_snapshots.keys.length} unique months for credit cards"
      
      # Calculate savings for each day
      savings_data = daily_dates.map do |date|
        calculate_value_for_date(date, all_savings_snapshots)
      end
      
      # Calculate spending for each day
      spending_data = daily_dates.map do |date|
        calculate_value_for_date(date, all_expense_snapshots)
      end
      
      # Net savings = savings - spending
      net_savings_data = daily_dates.map.with_index do |date, idx|
        (savings_data[idx] || 0) - (spending_data[idx] || 0)
      end
      
      Rails.logger.info "SavingsChartDataService: Calculated data arrays - savings: #{savings_data.length}, spending: #{spending_data.length}, net_savings: #{net_savings_data.length}"
      
      # Format for Lightweight Charts - time must be Unix timestamp in seconds
      result = {
        savings: daily_dates.map.with_index do |date, idx|
          {
            time: date.to_time.utc.to_i,
            value: (savings_data[idx] || 0).to_f.round(2)
          }
        end,
        spending: daily_dates.map.with_index do |date, idx|
          {
            time: date.to_time.utc.to_i,
            value: (spending_data[idx] || 0).to_f.round(2)
          }
        end,
        net_savings: daily_dates.map.with_index do |date, idx|
          {
            time: date.to_time.utc.to_i,
            value: (net_savings_data[idx] || 0).to_f.round(2)
          }
        end
      }
      
      # Validate data structure
      validate_chart_data(result)
      
      Rails.logger.info "SavingsChartDataService: Successfully generated chart data"
      result
    rescue => e
      Rails.logger.error "SavingsChartDataService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
  
  private
  
  def validate_chart_data(data)
    %i[savings spending net_savings].each do |series|
      unless data[series].is_a?(Array)
        raise "Invalid data format: #{series} is not an array"
      end
      
      data[series].each_with_index do |point, idx|
        unless point.is_a?(Hash)
          raise "Invalid data format: #{series}[#{idx}] is not a hash"
        end
        
        unless point[:time].is_a?(Integer)
          raise "Invalid time format: #{series}[#{idx}].time is not an integer (got #{point[:time].class})"
        end
        
        unless point[:value].is_a?(Numeric)
          raise "Invalid value format: #{series}[#{idx}].value is not numeric (got #{point[:value].class})"
        end
      end
    end
  rescue => e
    Rails.logger.error "Chart data validation error: #{e.message}"
    raise e
  end
  
  def calculate_value_for_date(date, snapshots_hash)
    month_start = date.beginning_of_month
    
    # Try to find exact match first
    snapshot = snapshots_hash[month_start]
    
    if snapshot && snapshot.any?
      # Sum all balances in cents, then convert to dollars
      snapshot.sum { |s| (s.amount_cents || 0) } / 100.0
    else
      # Interpolate from nearest snapshot
      nearest_snapshots = snapshots_hash.keys.sort
      if nearest_snapshots.any?
        nearest = nearest_snapshots.min_by { |d| (d - month_start).abs }
        if nearest && (nearest - month_start).abs < 3.months
          snapshots_hash[nearest].sum { |s| (s.amount_cents || 0) } / 100.0
        else
          0.0
        end
      else
        0.0
      end
    end
  rescue => e
    Rails.logger.error "Error calculating value for date #{date}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    0.0
  end
end

