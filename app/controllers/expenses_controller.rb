class ExpensesController < ApplicationController
  def index
    @expenses = current_user.expenses.order(created_at: :desc)
    redirect_to savings_accounts_path
  end
  
  def create
    @expense = current_user.expenses.build(expense_params)
    if @expense.save
      redirect_to savings_accounts_path, notice: 'Expense category added.'
    else
      flash.now[:alert] = 'Error adding expense.'
      redirect_to savings_accounts_path
    end
  end
  
  def destroy
    @expense = current_user.expenses.find(params[:id])
    @expense.destroy
    redirect_to savings_accounts_path, notice: 'Expense removed.'
  end
  
  private
  
  def expense_params
    params.require(:expense).permit(:name, :notes)
  end
end
