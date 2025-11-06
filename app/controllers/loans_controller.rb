class LoansController < ApplicationController
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
  
  def calculate
    principal = params[:principal].to_f
    interest_rate = params[:interest_rate].to_f
    rate_type = params[:rate_type] || 'apr'
    term_years = params[:term_years].to_f
    payment_frequency = params[:payment_frequency] || 'monthly'
    compounding_period = params[:compounding_period] || 'monthly'
    
    # Convert APY to APR if needed
    if rate_type == 'apy'
      # APY = (1 + APR/n)^n - 1, solving for APR
      # APR = n * ((1 + APY)^(1/n) - 1)
      compounding_per_year = case compounding_period
                            when 'daily' then 365
                            when 'monthly' then 12
                            when 'quarterly' then 4
                            when 'annually' then 1
                            else 12
                            end
      apr = compounding_per_year * (((1 + interest_rate / 100.0) ** (1.0 / compounding_per_year)) - 1)
      interest_rate = apr * 100.0
    end
    
    # Payment frequency periods per year
    payments_per_year = case payment_frequency
                       when 'weekly' then 52
                       when 'biweekly' then 26
                       when 'monthly' then 12
                       when 'quarterly' then 4
                       else 12
                       end
    
    # Compounding periods per year
    compounding_per_year = case compounding_period
                           when 'daily' then 365
                           when 'monthly' then 12
                           when 'quarterly' then 4
                           when 'annually' then 1
                           else 12
                           end
    
    # Calculate periodic interest rate
    periodic_rate = interest_rate / 100.0 / compounding_per_year
    
    # Number of payments
    total_payments = (term_years * payments_per_year).to_i
    
    # Calculate periodic payment using amortization formula
    # Adjust rate for payment frequency vs compounding frequency
    effective_rate = ((1 + periodic_rate) ** (compounding_per_year.to_f / payments_per_year)) - 1
    
    if effective_rate == 0
      periodic_payment = principal / total_payments
    else
      periodic_payment = principal * (effective_rate * (1 + effective_rate)**total_payments) / ((1 + effective_rate)**total_payments - 1)
    end
    
    # Calculate amortization schedule
    balance = principal
    amortization_schedule = []
    total_interest = 0
    
    total_payments.times do |payment_num|
      interest_payment = balance * effective_rate
      principal_payment = periodic_payment - interest_payment
      balance -= principal_payment
      
      # Ensure balance doesn't go negative
      if balance < 0
        principal_payment += balance
        balance = 0
      end
      
      total_interest += interest_payment
      
      amortization_schedule << {
        payment_number: payment_num + 1,
        payment_amount: periodic_payment.round(2),
        principal: principal_payment.round(2),
        interest: interest_payment.round(2),
        balance: balance.round(2)
      }
      
      break if balance <= 0
    end
    
    # Average principal and interest per payment
    avg_principal_per_payment = principal / total_payments
    avg_interest_per_payment = total_interest / total_payments
    
    # Effective annual rate
    effective_annual_rate = ((1 + effective_rate) ** payments_per_year - 1) * 100
    
    render json: {
      periodic_payment: periodic_payment.round(2),
      total_payments: total_payments,
      total_principal: principal.round(2),
      total_interest: total_interest.round(2),
      total_amount: (principal + total_interest).round(2),
      principal_per_payment: avg_principal_per_payment.round(2),
      interest_per_payment: avg_interest_per_payment.round(2),
      effective_rate: effective_annual_rate.round(2),
      amortization_schedule: amortization_schedule
    }
  end
  
  private
  
  def loan_params
    params.require(:loan).permit(:name, :principal, :interest_rate, :term_years, :status)
  end
end
