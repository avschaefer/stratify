class SavingsAccountsController < ApplicationController
  def index
    @accounts = current_user.savings_accounts.includes(:monthly_snapshots).order(:account_type, :name)
    @account = SavingsAccount.new(user: current_user)
    
    # Calculate net savings for past 3 months
    total_2_months_ago = @accounts.sum { |a| a.monthly_snapshots.find_by(recorded_at: 2.months.ago.beginning_of_month)&.balance || 0 }
    total_1_month_ago = @accounts.sum { |a| a.monthly_snapshots.find_by(recorded_at: 1.month.ago.beginning_of_month)&.balance || 0 }
    total_current = @accounts.sum { |a| a.monthly_snapshots.find_by(recorded_at: Date.today.beginning_of_month)&.balance || 0 }
    
    @net_savings_1_month_ago = total_1_month_ago - total_2_months_ago
    @net_savings_current = total_current - total_1_month_ago
    
    @total_balance_2_months_ago = total_2_months_ago
    @total_balance_1_month_ago = total_1_month_ago
    @total_balance_current = total_current
  end
  
  def create
    @account = current_user.savings_accounts.build(account_params)
    if @account.save
      redirect_to savings_accounts_path, notice: 'Account added successfully.'
    else
      flash.now[:alert] = 'Error adding account.'
      render :index
    end
  end
  
  def destroy
    @account = current_user.savings_accounts.find(params[:id])
    @account.destroy
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
  
  private
  
  def account_params
    params.require(:savings_account).permit(:name, :account_type, :notes)
  end
end
