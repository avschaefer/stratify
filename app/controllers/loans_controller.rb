class LoansController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    @loans = current_user.loans.order(created_at: :desc)
    @loan = Loan.new(user: current_user)
  end
  
  def create
    @loan = current_user.loans.build(loan_params)
    if @loan.save
      redirect_to loans_path, notice: 'Loan saved successfully.'
    else
      flash.now[:alert] = 'Error saving loan.'
      render :index
    end
  end
  
  def destroy
    @loan = current_user.loans.find(params[:id])
    @loan.destroy
    redirect_to loans_path, notice: 'Loan removed.'
  end
  
  def edit
    @loan = current_user.loans.find(params[:id])
  end
  
  def update
    @loan = current_user.loans.find(params[:id])
    if @loan.update(loan_params)
      redirect_to loans_path, notice: 'Loan updated successfully.'
    else
      flash.now[:alert] = 'Error updating loan.'
      render :edit
    end
  end
  
  def calculate
    service = LoanCalculationService.new(
      principal: params[:principal].to_f,
      interest_rate: params[:interest_rate].to_f,
      term_years: params[:term_years].to_f,
      rate_type: params[:rate_type] || 'apr',
      payment_frequency: params[:payment_frequency] || 'monthly',
      compounding_period: params[:compounding_period] || 'monthly'
    )
    
    result = service.calculate
    render json: result
  rescue => e
    handle_calculation_error(e)
  end
  
  private
  
  def loan_params
    params.require(:loan).permit(:name, :principal, :interest_rate, :term_years, :status, :rate_type, :payment_frequency, :compounding_period, :notes)
  end
end
