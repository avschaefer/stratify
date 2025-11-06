# frozen_string_literal: true

# Concern for models that can have monthly snapshots
module Snapshotable
  extend ActiveSupport::Concern
  
  included do
    has_many :monthly_snapshots, as: :snapshotable, dependent: :destroy
  end
  
  # Get balance for a specific month
  def balance_for_month(month_date)
    monthly_snapshots.find_by(recorded_at: month_date.beginning_of_month)&.balance || 0
  end
  
  # Get current balance (this month)
  def current_balance
    balance_for_month(Date.today)
  end
  
  # Get latest snapshot
  def latest_snapshot
    monthly_snapshots.order(recorded_at: :desc).first
  end
end

