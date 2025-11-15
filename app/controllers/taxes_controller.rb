class TaxesController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    @taxes = current_user.taxes.order(year: :desc)
    @tax = Tax.new(user: current_user)
  end
  
  def create
    @tax = current_user.taxes.build(tax_params)
    if @tax.save
      redirect_to taxes_path, notice: 'Tax scenario saved successfully.'
    else
      flash.now[:alert] = 'Error saving tax scenario.'
      render :index
    end
  end
  
  def destroy
    @tax = current_user.taxes.find(params[:id])
    @tax.destroy
    redirect_to taxes_path, notice: 'Tax scenario removed.'
  end
  
  def edit
    @tax = current_user.taxes.find(params[:id])
  end
  
  def update
    @tax = current_user.taxes.find(params[:id])
    if @tax.update(tax_params)
      redirect_to taxes_path, notice: 'Tax scenario updated successfully.'
    else
      flash.now[:alert] = 'Error updating tax scenario.'
      render :edit
    end
  end
  
  private
  
  def tax_params
    # Accept frontend-friendly names (dollars) - model accessors will convert to cents
    params.require(:tax).permit(:name, :year, :gross_income, :deductions, 
                                 :taxable_income, :tax_paid, :refund, 
                                 :payment_period, :notes)
  end
end

