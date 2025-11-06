# frozen_string_literal: true

# Query object for monthly snapshots with efficient loading
module Snapshots
  class MonthlySnapshotsQuery
    def initialize(snapshotable)
      @snapshotable = snapshotable
    end
    
    def call
      @snapshotable.monthly_snapshots.order(recorded_at: :desc)
    end
    
    def for_month(month_date)
      call.find_by(recorded_at: month_date.beginning_of_month)
    end
    
    def for_date_range(start_date, end_date)
      call.where(recorded_at: start_date.beginning_of_month..end_date.end_of_month)
    end
    
    def latest
      call.first
    end
  end
  
  # Query object for filtering snapshots by date range
  class ByDateRangeQuery
    def initialize(user, start_date:, end_date:)
      @user = user
      @start_date = start_date
      @end_date = end_date
    end
    
    def call
      savings_snapshots = MonthlySnapshot
        .joins("INNER JOIN savings_accounts ON monthly_snapshots.snapshotable_type = 'SavingsAccount' AND monthly_snapshots.snapshotable_id = savings_accounts.id")
        .where(savings_accounts: { user_id: @user.id })
        .where(recorded_at: @start_date..@end_date)
      
      expense_snapshots = MonthlySnapshot
        .joins("INNER JOIN expenses ON monthly_snapshots.snapshotable_type = 'Expense' AND monthly_snapshots.snapshotable_id = expenses.id")
        .where(expenses: { user_id: @user.id })
        .where(recorded_at: @start_date..@end_date)
      
      MonthlySnapshot.where(id: savings_snapshots.select(:id).union(expense_snapshots.select(:id)))
    end
  end
end

