# frozen_string_literal: true

# Service for generating chart data for retirement scenarios
class RetirementChartDataService
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Generate chart data for active retirement scenario
  def generate(historical_months: 24, future_months_limit: 60)
    active_scenario = user.retirement_scenarios.order(created_at: :desc).first
    
    return empty_chart_data unless active_scenario
    
    projection_service = RetirementProjectionService.new(scenario: active_scenario)
    projection_service.chart_data(
      historical_months: historical_months,
      future_months_limit: future_months_limit
    )
  end
  
  # Generate withdrawal phase chart data
  def withdrawal_data(retirement_years: 30, monthly_withdrawal: 0)
    active_scenario = user.retirement_scenarios.order(created_at: :desc).first
    
    return empty_withdrawal_data unless active_scenario
    
    projection_service = RetirementProjectionService.new(scenario: active_scenario)
    projection_service.withdrawal_data(
      retirement_years: retirement_years,
      monthly_withdrawal: monthly_withdrawal
    )
  end
  
  private
  
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

