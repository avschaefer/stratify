# frozen_string_literal: true

# Presenter for dashboard data formatting
class DashboardPresenter
  attr_reader :user
  
  def initialize(user:)
    @user = user
  end
  
  # Format net worth with currency symbol
  def formatted_net_worth
    Money.new(amount: net_worth_service.net_worth, currency: user_currency).formatted
  end
  
  # Format total assets
  def formatted_total_assets
    Money.new(amount: net_worth_service.total_assets, currency: user_currency).formatted
  end
  
  # Format total liabilities
  def formatted_total_liabilities
    Money.new(amount: net_worth_service.total_liabilities, currency: user_currency).formatted
  end
  
  # Format monthly savings
  def formatted_monthly_savings
    Money.new(amount: net_worth_service.monthly_savings, currency: user_currency).formatted
  end
  
  # Format percentage with sign
  def formatted_percentage(value, show_sign: false)
    sign = show_sign && value >= 0 ? '+' : ''
    "#{sign}#{value.round(2)}%"
  end
  
  # Format date according to user preferences
  def formatted_date(date)
    return '' unless date.is_a?(Date) || date.is_a?(Time)
    
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
  
  # Format asset allocation as percentage
  def formatted_asset_allocation
    allocation = net_worth_service.asset_allocation
    total = allocation.values.sum
    
    return {} if total.zero?
    
    allocation.transform_values do |value|
      (value / total * 100).round(2)
    end
  end
  
  private
  
  def net_worth_service
    @net_worth_service ||= NetWorthService.new(user: user)
  end
  
  def user_currency
    user.currency || 'USD'
  end
end

