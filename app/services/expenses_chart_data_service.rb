# frozen_string_literal: true

# Service for generating chart data for expenses (credit spending) over time
class ExpensesChartDataService
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  # Generate chart data from user's monthly snapshots
  def generate
    begin
      Rails.logger.info "ExpensesChartDataService: Starting data generation for user #{user&.id}"

      # Ensure user exists
      unless user
        raise "User is required"
      end

      # Get all balances for credit card accounts (expenses)
      begin
        credit_cards = user.accounts.where(account_type: 2)
        Rails.logger.info "ExpensesChartDataService: Found #{credit_cards.count} credit card accounts"
      rescue => e
        Rails.logger.error "Error querying credit card accounts: #{e.message}"
        raise e
      end

      begin
        all_snapshots = credit_cards.flat_map(&:balances)
          .compact
          .select { |s| s.balance_date.present? && s.amount_cents.present? }
        Rails.logger.info "ExpensesChartDataService: Filtered balances: #{all_snapshots.length}"
      rescue => e
        Rails.logger.error "Error getting balances: #{e.message}"
        raise e
      end

      Rails.logger.info "ExpensesChartDataService: Found #{all_snapshots.length} total balances"

      # Group by month and calculate monthly totals
      # Since you pay in full, the balance = monthly expense
      begin
        monthly_expenses = all_snapshots.group_by { |s| s.balance_date.beginning_of_month }
          .transform_values { |snapshots| snapshots.sum { |s| (s.amount_cents || 0) } / 100.0 }
          .sort_by { |month, _| month }
          .to_h
        Rails.logger.info "ExpensesChartDataService: Monthly expenses calculated: #{monthly_expenses.inspect}"
      rescue => e
        Rails.logger.error "Error calculating monthly expenses: #{e.message}"
        raise e
      end

      Rails.logger.info "ExpensesChartDataService: Grouped into #{monthly_expenses.length} months with data: #{monthly_expenses.inspect}"

      # Create expenses data points for each month
      expenses_data = []
      if monthly_expenses.any?
        expenses_data = monthly_expenses.map do |month, total_expenses|
          {
            time: month.to_time.utc.to_i,
            value: total_expenses.round(2)
          }
        end
      end

      result = { expenses: expenses_data }

      # Validate data structure
      validate_chart_data(result)

      Rails.logger.info "ExpensesChartDataService: Successfully generated #{expenses_data.length} data points"
      result
    rescue => e
      Rails.logger.error "ExpensesChartDataService error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def validate_chart_data(data)
    %i[expenses].each do |series|
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
