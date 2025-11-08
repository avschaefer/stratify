# Explicitly load the service class to ensure it's available
require Rails.root.join('app', 'services', 'calculations', 'loan_calculation_service').to_s

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
    # Handle JSON request body
    if request.content_type&.include?('application/json')
      json_body = request.body.read
      request.body.rewind # Reset body for potential future reads
      json_params = JSON.parse(json_body)
      
      principal = json_params['principal']&.to_f || 0
      interest_rate = json_params['interest_rate']&.to_f || 0
      term_years = json_params['term_years']&.to_f || 0
      rate_type = json_params['rate_type'] || 'apr'
      payment_frequency = json_params['payment_frequency'] || 'monthly'
      compounding_period = json_params['compounding_period'] || 'monthly'
    else
      principal = params[:principal]&.to_f || 0
      interest_rate = params[:interest_rate]&.to_f || 0
      term_years = params[:term_years]&.to_f || 0
      rate_type = params[:rate_type] || 'apr'
      payment_frequency = params[:payment_frequency] || 'monthly'
      compounding_period = params[:compounding_period] || 'monthly'
    end
    
    service = LoanCalculationService.new(
      principal: principal,
      interest_rate: interest_rate,
      term_years: term_years,
      rate_type: rate_type,
      payment_frequency: payment_frequency,
      compounding_period: compounding_period
    )
    
    result = service.calculate
    render json: result
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parse error: #{e.message}"
    render json: { error: 'Invalid JSON format' }, status: :bad_request
  rescue => e
    Rails.logger.error "Loan calculation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if e.backtrace
    render json: { error: e.message }, status: :unprocessable_entity
  end
  
  private
  
  def loan_params
    params.require(:loan).permit(:name, :principal, :interest_rate, :term_years, :status, :rate_type, :payment_frequency, :compounding_period, :notes)
  end
end
