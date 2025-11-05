class SavingsAccountsController < ApplicationController
  def index
    # Mock account data with monthly snapshots
    accounts_data = [
      {
        id: 1,
        name: 'Chase Checking',
        account_type: 'checking',
        snapshots: [
          { month: 2.months.ago.beginning_of_month, balance: 11800.00 },
          { month: 1.month.ago.beginning_of_month, balance: 12100.00 },
          { month: Date.today.beginning_of_month, balance: 12500.00 }
        ]
      },
      {
        id: 2,
        name: 'High Yield Savings',
        account_type: 'savings',
        snapshots: [
          { month: 2.months.ago.beginning_of_month, balance: 43500.00 },
          { month: 1.month.ago.beginning_of_month, balance: 44300.00 },
          { month: Date.today.beginning_of_month, balance: 45200.00 }
        ]
      },
      {
        id: 3,
        name: 'Chase Sapphire',
        account_type: 'credit_card',
        snapshots: [
          { month: 2.months.ago.beginning_of_month, balance: -1850.00 },
          { month: 1.month.ago.beginning_of_month, balance: -1500.00 },
          { month: Date.today.beginning_of_month, balance: -1250.00 }
        ]
      }
    ]
    
    @accounts = accounts_data.map do |data|
      account = OpenStruct.new(
        id: data[:id],
        name: data[:name],
        account_type: data[:account_type],
        current_balance: data[:snapshots].last[:balance],
        monthly_snapshots: data[:snapshots].map { |s| OpenStruct.new(id: nil, recorded_at: s[:month], balance: s[:balance]) }
      )
      
      # Add balance attributes for each month
      account.balance_2_months_ago = data[:snapshots].find { |s| s[:month] == 2.months.ago.beginning_of_month }&.dig(:balance) || 0.00
      account.balance_1_month_ago = data[:snapshots].find { |s| s[:month] == 1.month.ago.beginning_of_month }&.dig(:balance) || 0.00
      
      # Find current month snapshot
      current_snapshot = data[:snapshots].find { |s| s[:month] == Date.today.beginning_of_month }
      account.balance_current = current_snapshot&.dig(:balance) || 0.00
      account.current_snapshot_id = current_snapshot ? 1 : nil # Mock ID for existing snapshot
      
      account
    end
    
    # Sort accounts: savings/checking together first, then credit cards
    # Within each group, sort by type then name
    # Group 1: savings/checking (order: savings first, then checking)
    # Group 2: credit_card
    @accounts = @accounts.sort_by do |a|
      section = (a.account_type == 'credit_card') ? 2 : 1
      type_order_within_section = { 'savings' => 1, 'checking' => 2 }
      [section, type_order_within_section[a.account_type.to_s] || 99, a.name]
    end
    
    # Calculate net savings for past 3 months
    # Net savings = change in total balance from previous month
    total_2_months_ago = @accounts.sum { |a| a.balance_2_months_ago || 0 }
    total_1_month_ago = @accounts.sum { |a| a.balance_1_month_ago || 0 }
    total_current = @accounts.sum { |a| a.balance_current || 0 }
    
    # Net savings = balance change from previous month
    # For 2 months ago: we don't have 3 months ago data, so we'll set to 0 or calculate from a baseline
    # We'll calculate net savings as the change from the previous month
    @net_savings_2_months_ago = total_2_months_ago - total_2_months_ago # Will be 0 since we don't have 3 months ago data
    @net_savings_1_month_ago = total_1_month_ago - total_2_months_ago
    @net_savings_current = total_current - total_1_month_ago
    
    # Store total balances for display
    @total_balance_2_months_ago = total_2_months_ago
    @total_balance_1_month_ago = total_1_month_ago
    @total_balance_current = total_current
    
    @account = SavingsAccount.new(user: current_user)
  end
  
  def create
    redirect_to savings_accounts_path, notice: 'Account added successfully.'
  end
  
  def destroy
    redirect_to savings_accounts_path, notice: 'Account removed.'
  end

  def chart_data
    base_date = Date.today - 365.days
    daily_dates = (0..364).map { |i| base_date + i.days }
    
    # Generate savings data (positive values, growing over time)
    savings_base = 55000.0
    savings_data = daily_dates.map do |date|
      daily_growth = 0.0005 + (rand - 0.5) * 0.005
      savings_base = savings_base * (1 + daily_growth)
      savings_base
    end
    
    # Generate spending data (positive values representing spending amounts)
    spending_base = 3000.0
    spending_data = daily_dates.map do |date|
      daily_change = 0.0003 + (rand - 0.5) * 0.003
      spending_base = spending_base * (1 + daily_change)
      spending_base
    end
    
    # Net savings = savings - spending (cumulative)
    net_savings_data = daily_dates.map.with_index do |date, idx|
      savings_data[idx] - spending_data[idx]
    end
    
    # Format for Lightweight Charts: { time: unix_timestamp_seconds, value: number }
    chart_data = {
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
    
    render json: chart_data
  end
end
