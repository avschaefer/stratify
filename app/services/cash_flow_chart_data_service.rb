# frozen_string_literal: true

# Service for generating chart data for cash flow over time
class CashFlowChartDataService
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  # Generate chart data from user's monthly snapshots
  def generate
    begin
      Rails.logger.info "CashFlowChartDataService: Starting data generation for user #{user&.id}"

      # Ensure user exists
      unless user
        raise "User is required"
      end

      # Get all monthly snapshots for savings/checking accounts (cash)
      begin
        cash_accounts = user.savings_accounts.where(account_type: [0, 1])
        Rails.logger.info "CashFlowChartDataService: Found #{cash_accounts.count} cash accounts"
      rescue => e
        Rails.logger.error "Error querying savings_accounts: #{e.message}"
        raise e
      end

      begin
        all_snapshots = cash_accounts.flat_map(&:monthly_snapshots)
          .compact
          .select { |s| s.recorded_at.present? && s.balance.present? }
        Rails.logger.info "CashFlowChartDataService: Filtered snapshots: #{all_snapshots.length}"
      rescue => e
        Rails.logger.error "Error getting monthly snapshots: #{e.message}"
        raise e
      end

      Rails.logger.info "CashFlowChartDataService: Found #{all_snapshots.length} total snapshots"

      # Group by month and calculate monthly totals
      begin
        monthly_totals = all_snapshots.group_by { |s| s.recorded_at.beginning_of_month }
          .transform_values { |snapshots| snapshots.sum { |s| s.balance.to_f } }
          .sort_by { |month, _| month }
          .to_h
        Rails.logger.info "CashFlowChartDataService: Monthly totals calculated: #{monthly_totals.inspect}"
      rescue => e
        Rails.logger.error "Error calculating monthly totals: #{e.message}"
        raise e
      end

      Rails.logger.info "CashFlowChartDataService: Grouped into #{monthly_totals.length} months with data: #{monthly_totals.inspect}"

      # Get portfolio investment data
      portfolio_investments = monthly_totals.any? ? get_portfolio_investment_data(monthly_totals.keys) : {}

      # Calculate cash flow for each month
      cash_flow_data = []
      if monthly_totals.any?
        monthly_totals.each_with_index do |(month, current_balance), index|
          # Get previous month's balance (if available)
          previous_balance = index > 0 ? monthly_totals[monthly_totals.keys[index - 1]] : current_balance

          # Get investments for this month
          investments = portfolio_investments[month] || 0.0

          # Cash Flow = (Current Cash - Previous Cash) + Investments
          cash_flow = (current_balance - previous_balance) + investments

          cash_flow_data << {
            time: month.to_time.utc.to_i,
            value: cash_flow.round(2)
          }
        end
      end

      # Ensure we always return an array, even if empty
      result = { cash_flow: cash_flow_data }

      # Validate data structure
      validate_chart_data(result)

      Rails.logger.info "CashFlowChartDataService: Successfully generated #{cash_flow_data.length} data points"
      result
    rescue => e
      Rails.logger.error "CashFlowChartDataService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def get_portfolio_investment_data(months)
    return {} if months.empty?

    # Group portfolios by month of purchase and calculate total investments
    portfolios = user.portfolios.where.not(purchase_date: nil)
    portfolio_by_month = portfolios.group_by { |p| p.purchase_date.beginning_of_month }

    monthly_investments = {}
    portfolio_by_month.each do |month, month_portfolios|
      monthly_investments[month] = month_portfolios.sum { |p| (p.purchase_price || 0) * (p.quantity || 0) }
    end

    monthly_investments
  end

  def validate_chart_data(data)
    %i[cash_flow].each do |series|
      unless data[series].is_a?(Array)
        raise "Invalid data format: #{series} is not an array"
      end

      data[series].each_with_index do |point, idx|
        unless point.is_a?(Hash)
          raise "Invalid data format: #{series}[#{idx}] is not a hash"
        end

        unless point[:time].is_a?(Integer)
          raise "Invalid time format: #{series}[#{idx}].time is not an integer (got #{point[:time].class})"
        end

        unless point[:value].is_a?(Numeric)
          raise "Invalid value format: #{series}[#{idx}].value is not numeric (got #{point[:value].class})"
        end
      end
    end
  rescue => e
    Rails.logger.error "Chart data validation error: #{e.message}"
    raise e
  end
end
