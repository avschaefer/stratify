class TaxScenariosController < ApplicationController
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
  
  private
  
  def scenario_params
    params.require(:tax_scenario).permit(:name, :year, :income, :deductions, :notes)
  end
end
