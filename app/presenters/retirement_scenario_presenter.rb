# frozen_string_literal: true

# Presenter for retirement scenario data formatting
class RetirementScenarioPresenter
  attr_reader :scenario, :user, :projection_service
  
  def initialize(scenario:, user:)
    @scenario = scenario
    @user = user
    @projection_service = RetirementProjectionService.new(scenario: scenario)
  end
  
  # Format current savings
  def formatted_current_savings
    Money.new(amount: scenario.current_savings, currency: user_currency).formatted
  end
  
  # Format target amount
  def formatted_target_amount
    Money.new(amount: scenario.target_amount, currency: user_currency).formatted
  end
  
  # Format projected value
  def formatted_projected_value
    Money.new(amount: projection_service.projected_value, currency: user_currency).formatted
  end
  
  # Format monthly contribution needed
  def formatted_monthly_contribution_needed
    Money.new(amount: projection_service.monthly_contribution_needed, currency: user_currency).formatted
  end
  
  # Format monthly contribution actual
  def formatted_monthly_contribution_actual
    Money.new(amount: scenario.monthly_contribution || 0, currency: user_currency).formatted
  end
  
  # Format gap to goal
  def formatted_gap_to_goal
    gap = projection_service.gap_to_goal
    Money.new(amount: gap, currency: user_currency).formatted
  end
  
  # Format progress percentage
  def formatted_progress_percentage
    "#{projection_service.progress_percentage.round(2)}%"
  end
  
  # Format expected return rate
  def formatted_expected_return_rate
    "#{scenario.expected_return_rate || 7.0}%"
  end
  
  # Format target date
  def formatted_target_date
    formatted_date(scenario.target_date)
  end
  
  # Format years to goal
  def formatted_years_to_goal
    "#{projection_service.years_to_goal} years"
  end
  
  private
  
  def formatted_date(date)
    return '' unless date
    
    date_obj = date.is_a?(Time) ? date.to_date : date
    
    case user.date_format
    when 'MM/DD/YYYY'
      date_obj.strftime('%m/%d/%Y')
    when 'DD/MM/YYYY'
      date_obj.strftime('%d/%m/%Y')
    when 'YYYY-MM-DD'
      date_obj.strftime('%Y-%m-%d')
    when 'DD.MM.YYYY'
      date_obj.strftime('%d.%m.%Y')
    else
      date_obj.strftime('%m/%d/%Y')
    end
  end
  
  def user_currency
    user.currency || 'USD'
  end
end

