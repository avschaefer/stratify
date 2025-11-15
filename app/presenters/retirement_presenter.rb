# frozen_string_literal: true

# Presenter for retirement data formatting
class RetirementPresenter
  attr_reader :retirement, :user, :projection_service
  
  def initialize(retirement:, user:)
    @retirement = retirement
    @user = user
    @projection_service = RetirementProjectionService.new(scenario: retirement)
  end
  
  # Format contribution annual
  def formatted_contribution_annual
    Money.new(amount: retirement.contribution_annual || 0, currency: user_currency).formatted
  end
  
  # Format withdrawal annual PV
  def formatted_withdrawal_annual_pv
    Money.new(amount: retirement.withdrawal_annual_pv || 0, currency: user_currency).formatted
  end
  
  # Format projected value
  def formatted_projected_value
    Money.new(amount: projection_service.projected_value, currency: user_currency).formatted
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
    "#{retirement.rate_mid || 7.0}%"
  end
  
  # Format years to goal
  def formatted_years_to_goal
    "#{retirement.years_to_target} years"
  end
  
  private
  
  def user_currency
    user.currency || 'USD'
  end
end

