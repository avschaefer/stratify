class SavingsAccountsController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    @accounts = current_user.savings_accounts.includes(:monthly_snapshots).order(:account_type, :name)
    @account = SavingsAccount.new(user: current_user)
    
    begin
      # Calculate net savings for past 3 months using NetWorthService
      net_worth_service = NetWorthService.new(user: current_user)
      
      total_2_months_ago = net_worth_service.total_savings_for_month(2.months.ago.beginning_of_month)
      total_1_month_ago = net_worth_service.total_savings_for_month(1.month.ago.beginning_of_month)
      total_current = net_worth_service.total_savings_for_month(Date.today.beginning_of_month)
      
      @net_savings_1_month_ago = total_1_month_ago - total_2_months_ago
      @net_savings_current = total_current - total_1_month_ago
      
      @total_balance_2_months_ago = total_2_months_ago
      @total_balance_1_month_ago = total_1_month_ago
      @total_balance_current = total_current
    rescue => e
      Rails.logger.error "Savings accounts error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Set default values on error
      @net_savings_1_month_ago = 0
      @net_savings_current = 0
      @total_balance_2_months_ago = 0
      @total_balance_1_month_ago = 0
      @total_balance_current = 0
      
      flash.now[:alert] = 'Unable to load savings data. Please try again.'
    end
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
  
  def edit
    @account = current_user.savings_accounts.find(params[:id])
  end
  
  def update
    @account = current_user.savings_accounts.find(params[:id])
    if @account.update(account_params)
      redirect_to savings_accounts_path, notice: 'Account updated successfully.'
    else
      flash.now[:alert] = 'Error updating account.'
      render :edit
    end
  end

  def chart_data
    chart_service = SavingsChartDataService.new(user: current_user)
    chart_data = chart_service.generate
    render json: chart_data
  rescue => e
    handle_calculation_error(e)
  end
  
  def bulk_update_snapshots
    @account = current_user.savings_accounts.find(params[:id])
    snapshots_data = params[:snapshots] || []
    
    errors = []
    saved_count = 0
    
    snapshots_data.each do |snapshot_params|
      recorded_at = Date.parse(snapshot_params[:recorded_at]).beginning_of_month
      balance = snapshot_params[:balance].to_f
      
      if snapshot_params[:id].present?
        # Update existing snapshot
        snapshot = @account.monthly_snapshots.find_by(id: snapshot_params[:id])
        if snapshot
          if snapshot.update(balance: balance, recorded_at: recorded_at)
            saved_count += 1
          else
            errors << "Failed to update snapshot for #{recorded_at.strftime('%B %Y')}: #{snapshot.errors.full_messages.join(', ')}"
          end
        else
          errors << "Snapshot not found for #{recorded_at.strftime('%B %Y')}"
        end
      else
        # Create new snapshot or update if one exists for this month
        existing = @account.monthly_snapshots.find_by(recorded_at: recorded_at)
        if existing
          if existing.update(balance: balance)
            saved_count += 1
          else
            errors << "Failed to update snapshot for #{recorded_at.strftime('%B %Y')}: #{existing.errors.full_messages.join(', ')}"
          end
        else
          snapshot = @account.monthly_snapshots.build(balance: balance, recorded_at: recorded_at)
          if snapshot.save
            saved_count += 1
          else
            errors << "Failed to create snapshot for #{recorded_at.strftime('%B %Y')}: #{snapshot.errors.full_messages.join(', ')}"
          end
        end
      end
    end
    
    if errors.any?
      render json: { success: false, errors: errors, saved_count: saved_count }, status: :unprocessable_entity
    else
      render json: { success: true, message: "Successfully saved #{saved_count} snapshot(s).", saved_count: saved_count }
    end
  rescue => e
    Rails.logger.error "Bulk update snapshots error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, errors: [e.message] }, status: :internal_server_error
  end
  
  private
  
  def account_params
    params.require(:savings_account).permit(:name, :account_type, :notes)
  end
end
