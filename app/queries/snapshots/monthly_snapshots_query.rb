# frozen_string_literal: true

# Query object for balances with efficient loading
# Updated to use Balance model instead of MonthlySnapshot
module Snapshots
  class MonthlySnapshotsQuery
    def initialize(account)
      @account = account
    end
    
    def call
      @account.balances.order(balance_date: :desc)
    end
    
    def for_month(month_date)
      call.find_by(balance_date: month_date.beginning_of_month)
    end
    
    def for_date_range(start_date, end_date)
      call.where(balance_date: start_date.beginning_of_month..end_date.end_of_month)
    end
    
    def latest
      call.first
    end
  end
  
  # Query object for filtering balances by date range
  class ByDateRangeQuery
    def initialize(user, start_date:, end_date:)
      @user = user
      @start_date = start_date
      @end_date = end_date
    end
    
    def call
      # Get all balances for accounts belonging to the user
      Balance
        .joins(:account)
        .where(accounts: { user_id: @user.id })
        .where(balance_date: @start_date..@end_date)
        .order(balance_date: :desc)
    end
  end
end

