# frozen_string_literal: true

# Presenter for portfolio data formatting
class PortfolioPresenter
  attr_reader :portfolio, :user
  
  def initialize(portfolio:, user:)
    @portfolio = portfolio
    @user = user
  end
  
  # Format portfolio value
  def formatted_value
    Money.new(amount: portfolio_value, currency: user_currency).formatted
  end
  
  # Format purchase price
  def formatted_purchase_price
    Money.new(amount: portfolio.purchase_price || 0, currency: user_currency).formatted
  end
  
  # Format quantity
  def formatted_quantity
    "#{portfolio.quantity || 0}"
  end
  
  # Format purchase date
  def formatted_purchase_date
    formatted_date(portfolio.purchase_date)
  end
  
  # Get portfolio value
  def portfolio_value
    (portfolio.purchase_price || 0) * (portfolio.quantity || 0)
  end
  
  # Format asset type
  def formatted_asset_type
    portfolio.asset_type&.humanize || 'Other'
  end
  
  # Format status
  def formatted_status
    portfolio.status&.humanize || 'Draft'
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

