class SavingsAccount < ApplicationRecord
  belongs_to :user
  has_many :monthly_snapshots, dependent: :destroy
  
  validates :name, presence: true
  validates :account_type, presence: true
  
  enum :account_type, { savings: 0, checking: 1, credit_card: 2 }
  
  def current_balance
    monthly_snapshots.order(recorded_at: :desc).first&.balance || 0
  end
  
  def balance_2_months_ago
    monthly_snapshots.find_by(recorded_at: 2.months.ago.beginning_of_month)&.balance || 0
  end
  
  def balance_1_month_ago
    monthly_snapshots.find_by(recorded_at: 1.month.ago.beginning_of_month)&.balance || 0
  end
  
  def balance_current
    monthly_snapshots.find_by(recorded_at: Date.today.beginning_of_month)&.balance || 0
  end
  
  def current_snapshot_id
    monthly_snapshots.find_by(recorded_at: Date.today.beginning_of_month)&.id
  end
end

