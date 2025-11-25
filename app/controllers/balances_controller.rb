class BalancesController < ApplicationController
  before_action :find_account, only: [:index, :create]
  before_action :find_balance, only: [:update, :destroy]
  
  def index
    @balances = @account.balances.order(balance_date: :desc)
    @balance = @account.balances.build(balance_date: Date.today)
  end

  def create
    @balance = @account.balances.build(balance_params)
    
    # Ensure account belongs to current user
    unless @account.user_id == current_user.id
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    if @balance.save
      redirect_back(fallback_location: root_path, notice: 'Balance added successfully.')
    else
      redirect_back(fallback_location: root_path, alert: "Error adding balance: #{@balance.errors.full_messages.join(', ')}")
    end
  end
  
  def update
    unless balance_belongs_to_user?
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    if @balance.update(balance_params)
      redirect_back(fallback_location: root_path, notice: 'Balance updated successfully.')
    else
      redirect_back(fallback_location: root_path, alert: "Error updating balance: #{@balance.errors.full_messages.join(', ')}")
    end
  end
  
  def destroy
    unless balance_belongs_to_user?
      redirect_back(fallback_location: root_path, alert: 'Access denied.')
      return
    end
    
    @balance.destroy
    redirect_back(fallback_location: root_path, notice: 'Balance removed successfully.')
  end
  
  private
  
  def find_account
    if params[:account_id]
      @account = current_user.accounts.find(params[:account_id])
    else
      redirect_back(fallback_location: root_path, alert: 'Invalid account.')
      return
    end
  end
  
  def find_balance
    @balance = Balance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_back(fallback_location: root_path, alert: 'Balance not found.')
  end
  
  def balance_belongs_to_user?
    return false unless @balance
    account = @balance.account
    return false unless account
    account.user_id == current_user.id
  end
  
  def balance_params
    params.require(:balance).permit(:amount_cents, :balance_date)
  end
end

