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
  
  private
  
  def account_params
    params.require(:savings_account).permit(:name, :account_type, :notes)
  end
end
