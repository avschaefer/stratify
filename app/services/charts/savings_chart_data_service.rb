# frozen_string_literal: true

# Service for generating chart data for savings and spending over time
class SavingsChartDataService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate chart data for the last year
  def generate(days: 365)
    base_date = Date.today - days.days
    daily_dates = (0..(days - 1)).map { |i| base_date + i.days }
    
    # Get all monthly snapshots for savings accounts
    savings_accounts = user.savings_accounts.includes(:monthly_snapshots)
    all_savings_snapshots = savings_accounts.flat_map(&:monthly_snapshots).group_by(&:recorded_at)
    
    # Get all monthly snapshots for expenses
    expenses = user.expenses.includes(:monthly_snapshots)
    all_expense_snapshots = expenses.flat_map(&:monthly_snapshots).group_by(&:recorded_at)
    
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
      savings_data[idx] - spending_data[idx]
    end
    
    # Format for Lightweight Charts
    {
      savings: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: savings_data[idx].round(2)
        }
      end,
      spending: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: spending_data[idx].round(2)
        }
      end,
      net_savings: daily_dates.map.with_index do |date, idx|
        {
          time: date.to_time.to_i,
          value: net_savings_data[idx].round(2)
        }
      end
    }
  end
  
  private
  
  def calculate_value_for_date(date, snapshots_hash)
    month_start = date.beginning_of_month
    snapshot = snapshots_hash[month_start]
    
    if snapshot
      snapshot.sum(&:balance)
    else
      # Interpolate from nearest snapshot
      nearest_snapshots = snapshots_hash.keys.sort
      if nearest_snapshots.any?
        nearest = nearest_snapshots.min_by { |d| (d - month_start).abs }
        if nearest && (nearest - month_start).abs < 3.months
          snapshots_hash[nearest].sum(&:balance)
        else
          0
        end
      else
        0
      end
    end
  end
end

