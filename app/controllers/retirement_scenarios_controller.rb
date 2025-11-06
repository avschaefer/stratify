class RetirementScenariosController < ApplicationController
  include Calculatable
  include ErrorHandler
  
  def index
    @scenarios = current_user.retirement_scenarios.order(created_at: :desc)
    @scenario = RetirementScenario.new(user: current_user)
    
    # Get active scenario for summary cards (first scenario by default)
    active_scenario = @scenarios.first
    
    if active_scenario
      projection_service = RetirementProjectionService.new(scenario: active_scenario)
      summary = projection_service.summary
      
      @current_progress = summary[:current_progress]
      @saved_amount = summary[:saved_amount]
      @goal_amount = summary[:goal_amount]
      @target_age = 65 # Would calculate from birth date and target_date
      @annual_withdrawal = 0
      @years_to_goal = summary[:years_to_goal]
      @expected_return_rate = summary[:expected_return_rate]
      @projected_value = summary[:projected_value]
      @gap_to_goal = summary[:gap_to_goal]
      @monthly_contribution_needed = summary[:monthly_contribution_needed]
      @monthly_contribution_actual = summary[:monthly_contribution_actual]
    else
      @current_progress = 0
      @saved_amount = 0
      @years_to_goal = 0
      @goal_amount = 0
      @target_age = 65
      @expected_return_rate = 7.0
      @projected_value = 0
      @gap_to_goal = 0
      @monthly_contribution_needed = 0
      @monthly_contribution_actual = 0
      @annual_withdrawal = 0
    end
  end
  
  def set_active
    @scenario = current_user.retirement_scenarios.find(params[:id])
    redirect_to retirement_scenarios_path, notice: 'Scenario set as active. (Note: Currently using first scenario as active)'
  end
  
  def create
    @scenario = current_user.retirement_scenarios.build(scenario_params)
    if @scenario.save
      redirect_to retirement_scenarios_path, notice: 'Scenario saved.'
    else
      flash.now[:alert] = 'Error saving scenario.'
      render :index
    end
  end
  
  def destroy
    @scenario = current_user.retirement_scenarios.find(params[:id])
    @scenario.destroy
    redirect_to retirement_scenarios_path, notice: 'Scenario removed.'
  end
  
  def edit
    @scenario = current_user.retirement_scenarios.find(params[:id])
  end
  
  def update
    @scenario = current_user.retirement_scenarios.find(params[:id])
    if @scenario.update(scenario_params)
      redirect_to retirement_scenarios_path, notice: 'Scenario updated successfully.'
    else
      flash.now[:alert] = 'Error updating scenario.'
      render :edit
    end
  end
  
  def chart_data
    chart_service = RetirementChartDataService.new(user: current_user)
    chart_data = chart_service.generate
    render json: chart_data
  rescue => e
    handle_calculation_error(e)
  end
  
  def withdrawal_data
    chart_service = RetirementChartDataService.new(user: current_user)
    withdrawal_data = chart_service.withdrawal_data
    render json: withdrawal_data
  rescue => e
    handle_calculation_error(e)
  end
  
  private
  
  def scenario_params
    params.require(:retirement_scenario).permit(:name, :target_date, :current_savings, :monthly_contribution, :target_amount, :expected_return_rate, :risk_level)
  end
end
