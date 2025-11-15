class AccountsController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    # Order accounts: savings/checking together by index, then credit_card by index
    @accounts = current_user.accounts.includes(:balances)
      .order(Arel.sql('CASE WHEN account_type = 2 THEN 1 ELSE 0 END, "index", name'))
    @account = Account.new(user: current_user)
    
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
      Rails.logger.error "Accounts error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Set default values on error
      @net_savings_1_month_ago = 0
      @net_savings_current = 0
      @total_balance_2_months_ago = 0
      @total_balance_1_month_ago = 0
      @total_balance_current = 0
      
      flash.now[:alert] = 'Unable to load accounts data. Please try again.'
    end
  end
  
  def create
    @account = current_user.accounts.build(account_params)
    # Set index to be last in the account type group
    max_index = current_user.accounts.where(account_type: @account.account_type).maximum(:index) || -1
    @account.index = max_index + 1
    if @account.save
      redirect_to accounts_path, notice: 'Account added successfully.'
    else
      flash.now[:alert] = 'Error adding account.'
      render :index
    end
  end
  
  def destroy
    @account = current_user.accounts.find(params[:id])
    @account.destroy
    redirect_to accounts_path, notice: 'Account removed.'
  end
  
  def edit
    @account = current_user.accounts.find(params[:id])
  end
  
  def update
    @account = current_user.accounts.find(params[:id])
    if @account.update(account_params)
      redirect_to accounts_path, notice: 'Account updated successfully.'
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

  def cash_flow_chart_data
    Rails.logger.info "Cash flow chart data requested"
    if current_user.nil?
      Rails.logger.error "No current user found"
      render json: { error: "Authentication required", cash_flow: [] }, status: :unauthorized
      return
    end

    Rails.logger.info "Cash flow chart data requested for user #{current_user.id}"
    chart_service = CashFlowChartDataService.new(user: current_user)
    chart_data = chart_service.generate
    Rails.logger.info "Cash flow chart data generated successfully: #{chart_data.inspect}"
    render json: chart_data
  rescue => e
    Rails.logger.error "Cash flow chart data error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message, cash_flow: [] }, status: :internal_server_error
  end

  def expenses_chart_data
    Rails.logger.info "Expenses chart data requested"
    if current_user.nil?
      Rails.logger.error "No current user found"
      render json: { error: "Authentication required", expenses: [] }, status: :unauthorized
      return
    end

    Rails.logger.info "Expenses chart data requested for user #{current_user.id}"
    chart_service = ExpensesChartDataService.new(user: current_user)
    chart_data = chart_service.generate
    Rails.logger.info "Expenses chart data generated successfully: #{chart_data.inspect}"
    render json: chart_data
  rescue => e
    Rails.logger.error "Expenses chart data error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message, expenses: [] }, status: :internal_server_error
  end
  
  def bulk_update_snapshots
    @account = current_user.accounts.find(params[:id])
    snapshots_data = params[:snapshots] || []
    
    errors = []
    saved_count = 0
    
    snapshots_data.each do |snapshot_params|
      balance_date = Date.parse(snapshot_params[:recorded_at] || snapshot_params[:balance_date]).beginning_of_month
      # Handle both old format (balance in dollars) and new format (amount in dollars, or amount_cents in cents)
      amount_cents = if snapshot_params[:amount_cents]
        snapshot_params[:amount_cents].to_i
      else
        (snapshot_params[:balance]&.to_f || snapshot_params[:amount]&.to_f || 0) * 100
      end
      
      if snapshot_params[:id].present?
        # Update existing balance
        balance = @account.balances.find_by(id: snapshot_params[:id])
        if balance
          if balance.update(amount_cents: amount_cents.round, balance_date: balance_date)
            saved_count += 1
          else
            errors << "Failed to update balance for #{balance_date.strftime('%B %Y')}: #{balance.errors.full_messages.join(', ')}"
          end
        else
          errors << "Balance not found for #{balance_date.strftime('%B %Y')}"
        end
      else
        # Create new balance or update if one exists for this month
        existing = @account.balances.find_by(balance_date: balance_date)
        if existing
          if existing.update(amount_cents: amount_cents.round)
            saved_count += 1
          else
            errors << "Failed to update balance for #{balance_date.strftime('%B %Y')}: #{existing.errors.full_messages.join(', ')}"
          end
        else
          balance = @account.balances.build(amount_cents: amount_cents.round, balance_date: balance_date)
          if balance.save
            saved_count += 1
          else
            errors << "Failed to create balance for #{balance_date.strftime('%B %Y')}: #{balance.errors.full_messages.join(', ')}"
          end
        end
      end
    end
    
    if errors.any?
      render json: { success: false, errors: errors, saved_count: saved_count }, status: :unprocessable_entity
    else
      render json: { success: true, message: "Successfully saved #{saved_count} balance(s).", saved_count: saved_count }
    end
  rescue => e
    Rails.logger.error "Bulk update balances error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, errors: [e.message] }, status: :internal_server_error
  end
  
  def reorder
    account_ids = params[:account_ids] || []
    account_type = params[:account_type]
    
    Rails.logger.info "Reorder request: account_ids=#{account_ids.inspect}, account_type=#{account_type.inspect}"
    
    if account_ids.empty?
      render json: { success: false, errors: ['No account IDs provided'] }, status: :unprocessable_entity
      return
    end
    
    if account_type.blank?
      render json: { success: false, errors: ['Account type is required'] }, status: :unprocessable_entity
      return
    end
    
    # Handle cash_group which includes both savings and checking account types
    if account_type == 'cash_group'
      accounts = current_user.accounts.where(id: account_ids).where(account_type: ['savings', 'checking'])
      
      Rails.logger.info "Found #{accounts.count} accounts out of #{account_ids.count} requested for cash_group"
      
      if accounts.count != account_ids.count
        actual_accounts = current_user.accounts.where(id: account_ids)
        actual_types = actual_accounts.pluck(:id, :account_type).to_h
        Rails.logger.error "Account type mismatch. Expected savings or checking, Actual types: #{actual_types.inspect}"
        render json: { success: false, errors: ["Invalid account IDs or account types. Expected savings or checking accounts."] }, status: :unprocessable_entity
        return
      end
    else
      accounts = current_user.accounts.where(id: account_ids, account_type: account_type)
      
      Rails.logger.info "Found #{accounts.count} accounts out of #{account_ids.count} requested for account_type #{account_type}"
      
      if accounts.count != account_ids.count
        actual_accounts = current_user.accounts.where(id: account_ids)
        actual_types = actual_accounts.pluck(:id, :account_type).to_h
        Rails.logger.error "Account type mismatch. Requested type: #{account_type}, Actual types: #{actual_types.inspect}"
        render json: { success: false, errors: ["Invalid account IDs or account types. Expected #{account_type}, but found different types."] }, status: :unprocessable_entity
        return
      end
    end
    
    # Check if index column exists
    unless Account.column_names.include?('index')
      render json: { success: false, errors: ['Index column does not exist. Please run migrations.'] }, status: :internal_server_error
      return
    end
    
    # Update indices - use a transaction to ensure atomicity
    updated_count = 0
    ActiveRecord::Base.transaction do
      account_ids.each_with_index do |account_id, index|
        if account_type == 'cash_group'
          account = current_user.accounts.where(id: account_id, account_type: ['savings', 'checking']).first
        else
          account = current_user.accounts.find_by(id: account_id, account_type: account_type)
        end
        
        if account
          account.update_column(:index, index)
          updated_count += 1
          Rails.logger.info "Updated account #{account_id} (#{account.account_type}) index to #{index}"
        else
          raise ActiveRecord::RecordNotFound, "Account #{account_id} not found or wrong type"
        end
      end
    end
    
    Rails.logger.info "Successfully updated #{updated_count} account indices"
    render json: { success: true, message: 'Accounts reordered successfully', updated_count: updated_count }
  rescue => e
    Rails.logger.error "Reorder accounts error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, errors: [e.message] }, status: :internal_server_error
  end
  
  private
  
  def account_params
    params.require(:account).permit(:name, :account_type, :index, :notes)
  end
end

