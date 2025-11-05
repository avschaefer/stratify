class ExpensesController < ApplicationController
  def index
    redirect_to savings_accounts_path
  end
  
  def create
    redirect_to savings_accounts_path, notice: 'Expense category added.'
  end
  
  def destroy
    redirect_to savings_accounts_path, notice: 'Expense removed.'
  end
end
