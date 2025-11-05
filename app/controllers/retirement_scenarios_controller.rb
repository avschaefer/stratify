class RetirementScenariosController < ApplicationController
  def index
    # Mock scenarios for UI display
    @scenarios = [
      OpenStruct.new(
        id: 1,
        name: 'Conservative',
        risk_level: 'conservative',
        target_date: Date.new(2036, 1, 1),
        target_amount: 1500000.00,
        yearly_withdrawal: 45000.00,
        progress_percentage: 68.0,
        current_savings: 975000.00,
        active: true
      ),
      OpenStruct.new(
        id: 2,
        name: 'Moderate',
        risk_level: 'moderate',
        target_date: Date.new(2035, 1, 1),
        target_amount: 1800000.00,
        yearly_withdrawal: 52000.00,
        progress_percentage: 54.0,
        current_savings: 975000.00,
        active: false
      ),
      OpenStruct.new(
        id: 3,
        name: 'Aggressive',
        risk_level: 'aggressive',
        target_date: Date.new(2034, 1, 1),
        target_amount: 2100000.00,
        yearly_withdrawal: 60000.00,
        progress_percentage: 46.0,
        current_savings: 975000.00,
        active: false
      )
    ]
    
    @scenario = RetirementScenario.new(user: current_user)
    
    # Get active scenario for summary cards
    active_scenario = @scenarios.find { |s| s.active == true } || @scenarios.first
    
    if active_scenario
      @current_progress = active_scenario.progress_percentage
      @saved_amount = active_scenario.current_savings
      @goal_amount = active_scenario.target_amount
      @target_age = 65 # Would calculate from birth date and target_date
      
      # Calculate years to goal
      years_to_goal = active_scenario.target_date.year - Date.today.year
      @years_to_goal = [years_to_goal, 0].max
    else
      @current_progress = 0
      @saved_amount = 0
      @years_to_goal = 0
      @goal_amount = 0
      @target_age = 65
    end
  end
  
  def set_active
    # In a real app, this would update the active scenario in the database
    redirect_to retirement_scenarios_path, notice: 'Scenario set as active.'
  end
  
  def create
    redirect_to retirement_scenarios_path, notice: 'Scenario saved.'
  end
  
  def calculate
    render json: {
      projected_value: 0,
      progress_percentage: 0,
      years_to_target: 0
    }
  end
  
  def destroy
    redirect_to retirement_scenarios_path, notice: 'Scenario removed.'
  end
end
