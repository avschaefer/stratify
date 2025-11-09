class TaxScenariosController < ApplicationController
  include ErrorHandler
  
  def index
    @scenarios = current_user.tax_scenarios.order(created_at: :desc)
    @scenario = TaxScenario.new(user: current_user)
  end
  
  def create
    @scenario = current_user.tax_scenarios.build(scenario_params)
    if @scenario.save
      redirect_to tax_scenarios_path, notice: 'Tax scenario saved.'
    else
      @scenarios = current_user.tax_scenarios.order(created_at: :desc)
      flash.now[:alert] = 'Error saving tax scenario. Please fill out all required fields.'
      render :index, status: :unprocessable_entity
    end
  end
  
  def destroy
    @scenario = current_user.tax_scenarios.find(params[:id])
    @scenario.destroy
    redirect_to tax_scenarios_path, notice: 'Scenario removed.'
  end
  
  def edit
    @scenario = current_user.tax_scenarios.find(params[:id])
  end
  
  def update
    @scenario = current_user.tax_scenarios.find(params[:id])
    if @scenario.update(scenario_params)
      redirect_to tax_scenarios_path, notice: 'Tax scenario updated successfully.'
    else
      flash.now[:alert] = 'Error updating tax scenario. Please fill out all required fields.'
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def scenario_params
    params.require(:tax_scenario).permit(:name, :year, :income, :deductions, :taxable_income, :tax_paid, :refund, :notes)
  end
end
