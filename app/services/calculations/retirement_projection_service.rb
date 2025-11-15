# frozen_string_literal: true

# Service for calculating retirement projections, contributions, and withdrawal scenarios
# Updated to work with new Retirement model
class RetirementProjectionService
  attr_reader :scenario
  
  def initialize(scenario:)
    @scenario = scenario
  end
  
  # Calculate projected value at retirement using current savings and monthly contributions
  def projected_value
    return current_savings if years_to_goal <= 0
    
    monthly_rate = monthly_rate_for(expected_return_rate)
    months = months_to_goal
    
    future_value_of_savings = current_savings * (1 + monthly_rate)**months
    future_value_of_contributions = monthly_contribution * (((1 + monthly_rate)**months - 1) / monthly_rate)
    
    future_value_of_savings + future_value_of_contributions
  end
  
  # Calculate monthly contribution needed to reach target amount
  def monthly_contribution_needed
    return 0 if years_to_goal <= 0 || target_amount <= current_savings
    
    monthly_rate = monthly_rate_for(expected_return_rate)
    months = months_to_goal
    
    if monthly_rate > 0
      future_value_of_current = current_savings * (1 + monthly_rate)**months
      needed_from_contributions = target_amount - future_value_of_current
      
      if needed_from_contributions > 0
        needed_from_contributions * monthly_rate / ((1 + monthly_rate)**months - 1)
      else
        0
      end
    else
      (target_amount - current_savings) / months.to_f
    end
  end
  
  # Calculate years until target date (retirement age)
  def years_to_goal
    return 0 if scenario.age_retirement.nil? || scenario.age_start.nil?
    [scenario.age_retirement - scenario.age_start, 0].max
  end
  
  # Calculate months until target date
  def months_to_goal
    years_to_goal * 12
  end
  
  # Calculate projected value at retirement using actual contribution
  def projected_value_at_retirement
    return current_savings if months_to_goal <= 0
    
    monthly_rate = monthly_rate_for(expected_return_rate)
    months = months_to_goal
    
    if monthly_rate > 0
      current_savings * (1 + monthly_rate)**months +
        monthly_contribution * (((1 + monthly_rate)**months - 1) / monthly_rate)
    else
      current_savings + (monthly_contribution * months)
    end
  end
  
  # Calculate target value at retirement using required contribution
  def target_value_at_retirement
    return current_savings if months_to_goal <= 0
    
    monthly_rate = monthly_rate_for(expected_return_rate)
    months = months_to_goal
    contribution_needed = monthly_contribution_needed
    
    if monthly_rate > 0
      current_savings * (1 + monthly_rate)**months +
        contribution_needed * (((1 + monthly_rate)**months - 1) / monthly_rate)
    else
      current_savings + (contribution_needed * months)
    end
  end
  
  # Calculate gap between projected value and target
  def gap_to_goal
    projected_value - target_amount
  end
  
  # Calculate progress percentage
  def progress_percentage
    return 0 if target_amount.nil? || target_amount.zero?
    [projected_value / target_amount * 100, 100].min
  end
  
  # Generate chart data for accumulation phase
  def chart_data(historical_months: 24, future_months_limit: 60)
    return empty_chart_data if scenario.nil?
    
    base_date = Date.today
    years = years_to_goal
    months = months_to_goal
    
    monthly_rate = monthly_rate_for(expected_return_rate)
    monthly_contribution_actual = monthly_contribution
    monthly_contribution_needed_val = monthly_contribution_needed()
    
    # Generate historical dates (past 24 months)
    historical_dates = (-historical_months..0).map { |i| base_date + i.months }
    
    # Generate future monthly dates (limited for performance)
    future_monthly_dates = (1..[months, future_months_limit].min).map { |i| base_date + i.months }
    
    # Actual savings - historical data (working backwards from today)
    actual_savings_data = generate_historical_data(historical_dates, monthly_rate, monthly_contribution_actual)
    
    # Add today's point
    actual_savings_data << {
      time: base_date.to_time.to_i,
      value: current_savings.round(2)
    }
    
    # Projected savings using current contribution
    projected_savings_data = generate_future_data(
      future_monthly_dates,
      current_savings,
      monthly_rate,
      monthly_contribution_actual
    )
    
    # Target savings using required contribution
    target_savings_data = generate_future_data(
      future_monthly_dates,
      current_savings,
      monthly_rate,
      monthly_contribution_needed_val
    )
    
    {
      actual_savings: actual_savings_data,
      projected_savings: projected_savings_data,
      target_savings: target_savings_data,
      today_timestamp: base_date.to_time.to_i
    }
  end
  
  # Generate withdrawal phase chart data
  def withdrawal_data(retirement_years: 30, monthly_withdrawal: 0)
    return empty_withdrawal_data if scenario.nil?
    
    base_date = Date.today
    years = years_to_goal
    retirement_start_date = base_date + years.years
    retirement_end_date = retirement_start_date + retirement_years.years
    
    projected_value_at_ret = projected_value_at_retirement
    target_value_at_ret = target_value_at_retirement
    monthly_rate = monthly_rate_for(scenario.expected_return_rate)
    
    # Generate monthly dates during retirement
    total_months = retirement_years * 12
    monthly_dates = (0..[total_months, 360].min).map { |i| retirement_start_date + i.months }
    
    # Projected withdrawal (decaying from projected value)
    projected_withdrawal_data = generate_withdrawal_data(
      monthly_dates,
      projected_value_at_ret,
      monthly_rate,
      monthly_withdrawal
    )
    
    # Target withdrawal (decaying from target value)
    target_withdrawal_data = generate_withdrawal_data(
      monthly_dates,
      target_value_at_ret,
      monthly_rate,
      monthly_withdrawal
    )
    
    {
      projected_savings: projected_withdrawal_data,
      target_savings: target_withdrawal_data,
      retirement_start_timestamp: retirement_start_date.to_time.to_i,
      retirement_end_timestamp: retirement_end_date.to_time.to_i
    }
  end
  
  # Get summary metrics for dashboard
  def summary
    {
      current_progress: progress_percentage.round(2),
      saved_amount: current_savings,
      goal_amount: target_amount,
      years_to_goal: years_to_goal,
      expected_return_rate: expected_return_rate,
      projected_value: projected_value.round(2),
      gap_to_goal: gap_to_goal.round(2),
      monthly_contribution_needed: monthly_contribution_needed.round(2),
      monthly_contribution_actual: monthly_contribution
    }
  end
  
  private
  
  # Adapter methods for new Retirement model
  def current_savings
    # For new model, we assume current savings is 0 (tracked elsewhere)
    # This could be enhanced to pull from accounts in the future
    scenario.current_savings || 0
  end
  
  def target_amount
    # Calculate target based on withdrawal needs
    scenario.target_amount || begin
      return 0 if scenario.withdrawal_annual_pv_cents.nil? || scenario.withdrawal_rate_fv.nil? || scenario.withdrawal_rate_fv.zero?
      (scenario.withdrawal_annual_pv_cents / 100.0) / (scenario.withdrawal_rate_fv / 100.0)
    end
  end
  
  def monthly_contribution
    return 0 if scenario.contribution_annual_cents.nil?
    scenario.contribution_annual_cents / 100.0 / 12.0
  end
  
  def expected_return_rate
    scenario.expected_return_rate || scenario.rate_mid || 7.0
  end
  
  def target_date
    return nil if scenario.age_retirement.nil? || scenario.age_start.nil?
    Date.today + (scenario.age_retirement - scenario.age_start).years
  end
  
  def monthly_rate_for(annual_rate)
    (annual_rate || 7.0) / 100.0 / 12.0
  end
  
  def generate_historical_data(dates, monthly_rate, monthly_contribution_val)
    data = []
    current_value = current_savings
    
    # Work backwards from today
    dates.reverse.each do |date|
      if monthly_rate > 0
        current_value = (current_value - monthly_contribution_val) / (1 + monthly_rate)
      else
        current_value = current_value - monthly_contribution_val
      end
      data << {
        time: date.to_time.to_i,
        value: [current_value, 0].max.round(2)
      }
    end
    
    data.reverse # Return in chronological order
  end
  
  def generate_future_data(dates, start_value, monthly_rate, monthly_contribution)
    data = []
    current_value = start_value
    
    dates.each do |date|
      if monthly_rate > 0
        current_value = current_value * (1 + monthly_rate) + monthly_contribution
      else
        current_value = current_value + monthly_contribution
      end
      data << {
        time: date.to_time.to_i,
        value: current_value.round(2)
      }
    end
    
    data
  end
  
  def generate_withdrawal_data(dates, start_value, monthly_rate, monthly_withdrawal)
    data = []
    current_value = start_value
    
    dates.each do |date|
      if monthly_rate > 0
        current_value = current_value * (1 + monthly_rate) - monthly_withdrawal
      else
        current_value = current_value - monthly_withdrawal
      end
      data << {
        time: date.to_time.to_i,
        value: [current_value, 0].max.round(2)
      }
    end
    
    data
  end
  
  def empty_chart_data
    {
      actual_savings: [],
      projected_savings: [],
      target_savings: [],
      today_timestamp: Date.today.to_time.to_i
    }
  end
  
  def empty_withdrawal_data
    {
      projected_savings: [],
      target_savings: [],
      retirement_start_timestamp: Date.today.to_time.to_i,
      retirement_end_timestamp: (Date.today + 30.years).to_time.to_i
    }
  end
end

