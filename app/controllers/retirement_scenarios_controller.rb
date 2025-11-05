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
  
  def chart_data
    # Mock scenarios for chart data (same as index)
    scenarios = [
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
    
    # Get active scenario for chart data
    active_scenario = scenarios.find { |s| s.active == true } || scenarios.first
    
    if active_scenario
      saved_amount = active_scenario.current_savings
      goal_amount = active_scenario.target_amount
      years_to_goal = [active_scenario.target_date.year - Date.today.year, 0].max
      expected_return_rate = 7.0
      monthly_contribution_actual = 2000.0
      
      # Calculate monthly contribution needed
      monthly_rate = expected_return_rate / 100.0 / 12.0
      months_to_goal = years_to_goal * 12
      
      if months_to_goal > 0 && monthly_rate > 0
        future_value_of_current = saved_amount * (1 + monthly_rate) ** months_to_goal
        needed_from_contributions = goal_amount - future_value_of_current
        
        if needed_from_contributions > 0
          monthly_contribution_needed = needed_from_contributions * monthly_rate / 
                                       ((1 + monthly_rate) ** months_to_goal - 1)
        else
          monthly_contribution_needed = 0
        end
      else
        monthly_contribution_needed = (goal_amount - saved_amount) / 12.0
      end
    else
      saved_amount = 0
      goal_amount = 0
      years_to_goal = 0
      expected_return_rate = 7.0
      monthly_contribution_actual = 0
      monthly_contribution_needed = 0
    end
    
    # Generate dates from today to retirement date
    base_date = Date.today
    target_date = base_date + years_to_goal.years
    total_months = years_to_goal * 12
    
    # Generate historical data (past 24 months) up to today
    historical_months = 24
    historical_dates = (-historical_months..0).map { |i| base_date + i.months }
    
    # Generate future monthly data points (limit to 60 months max for performance)
    future_monthly_dates = (1..[total_months, 60].min).map { |i| base_date + i.months }
    
    monthly_rate = expected_return_rate / 100.0 / 12.0
    
    # Actual savings - historical data going backwards from today
    # We'll simulate growth backwards to get historical values
    actual_savings_data = []
    current_value = saved_amount
    
    # Work backwards from today to generate historical values
    historical_dates.reverse.each do |date|
      if monthly_rate > 0
        # Reverse the calculation: remove contribution and divide by growth
        current_value = (current_value - monthly_contribution_actual) / (1 + monthly_rate)
      else
        current_value = current_value - monthly_contribution_actual
      end
      actual_savings_data << {
        time: date.to_time.to_i,
        value: [current_value, 0].max.round(2)
      }
    end
    
    # Reverse to get chronological order (oldest to newest)
    actual_savings_data.reverse!
    
    # Add today's point
    actual_savings_data << {
      time: base_date.to_time.to_i,
      value: saved_amount.round(2)
    }
    
    # Projected savings given settings (using current monthly contribution) - from today forward
    projected_savings_data = []
    current_value = saved_amount
    future_monthly_dates.each do |date|
      if monthly_rate > 0
        current_value = current_value * (1 + monthly_rate) + monthly_contribution_actual
      else
        current_value = current_value + monthly_contribution_actual
      end
      projected_savings_data << {
        time: date.to_time.to_i,
        value: current_value.round(2)
      }
    end
    
    # Target goal savings given required settings (using required monthly contribution) - from today forward
    target_savings_data = []
    current_value = saved_amount
    future_monthly_dates.each do |date|
      if monthly_rate > 0
        current_value = current_value * (1 + monthly_rate) + monthly_contribution_needed
      else
        current_value = current_value + monthly_contribution_needed
      end
      target_savings_data << {
        time: date.to_time.to_i,
        value: current_value.round(2)
      }
    end
    
    chart_data = {
      actual_savings: actual_savings_data,
      projected_savings: projected_savings_data,
      target_savings: target_savings_data,
      today_timestamp: base_date.to_time.to_i
    }
    
    render json: chart_data
  end
  
  def withdrawal_data
    # Mock scenarios for withdrawal data (same as chart_data)
    scenarios = [
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
    
    # Get active scenario for withdrawal data
    active_scenario = scenarios.find { |s| s.active == true } || scenarios.first
    
    if active_scenario
      goal_amount = active_scenario.target_amount
      years_to_goal = [active_scenario.target_date.year - Date.today.year, 0].max
      expected_return_rate = 7.0
      monthly_contribution_actual = 2000.0
      yearly_withdrawal = active_scenario.yearly_withdrawal || 0
      monthly_withdrawal = yearly_withdrawal / 12.0
      
      # Calculate retirement end date (assuming 30 years of retirement)
      retirement_years = 30
      base_date = Date.today
      retirement_start_date = base_date + years_to_goal.years
      retirement_end_date = retirement_start_date + retirement_years.years
      
      # Calculate monthly contribution needed to reach goal
      monthly_rate = expected_return_rate / 100.0 / 12.0
      months_to_goal = years_to_goal * 12
      
      if months_to_goal > 0 && monthly_rate > 0
        saved_amount = active_scenario.current_savings
        future_value_of_current = saved_amount * (1 + monthly_rate) ** months_to_goal
        needed_from_contributions = goal_amount - future_value_of_current
        
        if needed_from_contributions > 0
          monthly_contribution_needed = needed_from_contributions * monthly_rate / 
                                       ((1 + monthly_rate) ** months_to_goal - 1)
        else
          monthly_contribution_needed = 0
        end
        
        # Calculate projected value at retirement start (using actual contribution)
        projected_value_at_retirement = saved_amount * (1 + monthly_rate) ** months_to_goal + 
                                        monthly_contribution_actual * (((1 + monthly_rate) ** months_to_goal - 1) / monthly_rate)
        
        # Calculate target value at retirement start (using required contribution)
        target_value_at_retirement = saved_amount * (1 + monthly_rate) ** months_to_goal + 
                                    monthly_contribution_needed * (((1 + monthly_rate) ** months_to_goal - 1) / monthly_rate)
      else
        projected_value_at_retirement = active_scenario.current_savings
        target_value_at_retirement = active_scenario.current_savings
      end
    else
      goal_amount = 0
      years_to_goal = 0
      expected_return_rate = 7.0
      monthly_withdrawal = 0
      retirement_years = 30
      base_date = Date.today
      retirement_start_date = base_date + years_to_goal.years
      retirement_end_date = retirement_start_date + retirement_years.years
      projected_value_at_retirement = 0
      target_value_at_retirement = 0
    end
    
    # Generate monthly dates from retirement start to retirement end
    total_months = retirement_years * 12
    monthly_dates = (0..[total_months, 360].min).map { |i| retirement_start_date + i.months }
    
    monthly_rate = expected_return_rate / 100.0 / 12.0
    
    # Projected savings during withdrawal (decaying from projected value at retirement)
    projected_withdrawal_data = []
    current_value = projected_value_at_retirement
    monthly_dates.each do |date|
      if monthly_rate > 0
        # Growth minus withdrawal
        current_value = current_value * (1 + monthly_rate) - monthly_withdrawal
      else
        current_value = current_value - monthly_withdrawal
      end
      projected_withdrawal_data << {
        time: date.to_time.to_i,
        value: [current_value, 0].max.round(2)
      }
    end
    
    # Target savings during withdrawal (decaying from target value at retirement)
    target_withdrawal_data = []
    current_value = target_value_at_retirement
    monthly_dates.each do |date|
      if monthly_rate > 0
        # Growth minus withdrawal
        current_value = current_value * (1 + monthly_rate) - monthly_withdrawal
      else
        current_value = current_value - monthly_withdrawal
      end
      target_withdrawal_data << {
        time: date.to_time.to_i,
        value: [current_value, 0].max.round(2)
      }
    end
    
    withdrawal_data = {
      projected_savings: projected_withdrawal_data,
      target_savings: target_withdrawal_data,
      retirement_start_timestamp: retirement_start_date.to_time.to_i,
      retirement_end_timestamp: retirement_end_date.to_time.to_i
    }
    
    render json: withdrawal_data
  end
end
