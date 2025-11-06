class TaxScenariosController < ApplicationController
  include Calculatable
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
      flash.now[:alert] = 'Error saving tax scenario.'
      render :index
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
      flash.now[:alert] = 'Error updating tax scenario.'
      render :edit
    end
  end
  
  def calculate
    scenario_id = params[:scenario_id]
    scenario = current_user.tax_scenarios.find_by(id: scenario_id) if scenario_id.present?
    
    if scenario
      service = TaxCalculationService.new(
        income: scenario.income || 0,
        deductions: scenario.deductions || 0,
        year: scenario.year || Date.today.year
      )
      
      result = service.calculate
      render json: result
    else
      render json: { error: 'Tax scenario not found' }, status: :not_found
    end
  rescue => e
    handle_calculation_error(e)
  end
  
  private
  
  def scenario_params
    params.require(:tax_scenario).permit(:name, :year, :income, :deductions, :notes)
  end
end
