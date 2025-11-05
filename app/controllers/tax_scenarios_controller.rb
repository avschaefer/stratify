class TaxScenariosController < ApplicationController
  def index
    @scenarios = []
    @scenario = TaxScenario.new(user: current_user)
  end
  
  def create
    redirect_to tax_scenarios_path, notice: 'Tax scenario saved.'
  end
  
  def calculate
    render json: {
      taxable_income: 0,
      tax_rate: 0,
      estimated_tax: 0,
      after_tax_income: 0,
      bracket_range: "$0 - $0"
    }
  end
  
  def destroy
    redirect_to tax_scenarios_path, notice: 'Scenario removed.'
  end
end
