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
      @annual_withdrawal = active_scenario.yearly_withdrawal || 0
      
      # Calculate years to goal
      years_to_goal = active_scenario.target_date.year - Date.today.year
      @years_to_goal = [years_to_goal, 0].max
      
      # Calculate additional metrics for 8 tiles
      @expected_return_rate = 7.0 # Default expected return rate
      
      # Monthly contribution actual (mock data - would come from user's actual contributions)
      @monthly_contribution_actual = 2000.0
      
      # Calculate projected value at retirement
      monthly_rate = @expected_return_rate / 100.0 / 12.0
      months_to_goal = @years_to_goal * 12
      
      if months_to_goal > 0 && monthly_rate > 0
        @projected_value = @saved_amount * (1 + monthly_rate) ** months_to_goal + 
                          @monthly_contribution_actual * (((1 + monthly_rate) ** months_to_goal - 1) / monthly_rate)
      else
        @projected_value = @saved_amount
      end
      
      # Calculate gap to goal
      @gap_to_goal = @projected_value - @goal_amount
      
      # Calculate monthly contribution needed to reach goal
      if months_to_goal > 0 && monthly_rate > 0
        future_value_of_current = @saved_amount * (1 + monthly_rate) ** months_to_goal
        needed_from_contributions = @goal_amount - future_value_of_current
        
        if needed_from_contributions > 0
          @monthly_contribution_needed = needed_from_contributions * monthly_rate / 
                                        ((1 + monthly_rate) ** months_to_goal - 1)
        else
          @monthly_contribution_needed = 0
        end
      else
        @monthly_contribution_needed = (@goal_amount - @saved_amount) / 12.0
      end
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
