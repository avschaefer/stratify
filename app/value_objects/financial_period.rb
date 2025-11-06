# frozen_string_literal: true

# Value object representing financial periods (monthly, quarterly, yearly)
# Handles date calculations and period comparisons
class FinancialPeriod
  attr_reader :date, :period_type
  
  PERIOD_TYPES = %w[monthly quarterly yearly].freeze
  
  def initialize(date:, period_type: 'monthly')
    @date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    @period_type = period_type.to_s.downcase
    
    validate!
  end
  
  def start_of_period
    case period_type
    when 'monthly'
      date.beginning_of_month
    when 'quarterly'
      quarter_start_month = ((date.month - 1) / 3) * 3 + 1
      Date.new(date.year, quarter_start_month, 1)
    when 'yearly'
      date.beginning_of_year
    end
  end
  
  def end_of_period
    case period_type
    when 'monthly'
      date.end_of_month
    when 'quarterly'
      quarter_end_month = ((date.month - 1) / 3) * 3 + 3
      Date.new(date.year, quarter_end_month, -1)
    when 'yearly'
      date.end_of_year
    end
  end
  
  def next_period
    next_date = case period_type
                when 'monthly'
                  date + 1.month
                when 'quarterly'
                  date + 3.months
                when 'yearly'
                  date + 1.year
                end
    
    FinancialPeriod.new(date: next_date, period_type: period_type)
  end
  
  def previous_period
    prev_date = case period_type
                when 'monthly'
                  date - 1.month
                when 'quarterly'
                  date - 3.months
                when 'yearly'
                  date - 1.year
                end
    
    FinancialPeriod.new(date: prev_date, period_type: period_type)
  end
  
  def periods_until(target_date)
    target = target_date.is_a?(Date) ? target_date : Date.parse(target_date.to_s)
    return 0 if target <= date
    
    case period_type
    when 'monthly'
      ((target.year - date.year) * 12) + (target.month - date.month)
    when 'quarterly'
      ((target.year - date.year) * 4) + ((target.month - 1) / 3) - ((date.month - 1) / 3)
    when 'yearly'
      target.year - date.year
    end
  end
  
  def period_number
    case period_type
    when 'monthly'
      date.month
    when 'quarterly'
      ((date.month - 1) / 3) + 1
    when 'yearly'
      date.year
    end
  end
  
  def ==(other)
    return false unless other.is_a?(FinancialPeriod)
    date == other.date && period_type == other.period_type
  end
  
  def to_s
    case period_type
    when 'monthly'
      date.strftime('%B %Y')
    when 'quarterly'
      quarter = ((date.month - 1) / 3) + 1
      "Q#{quarter} #{date.year}"
    when 'yearly'
      date.year.to_s
    end
  end
  
  private
  
  def validate!
    raise ArgumentError, "Invalid period type: #{period_type}" unless PERIOD_TYPES.include?(period_type)
  end
end

