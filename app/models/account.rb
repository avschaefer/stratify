class Account < ApplicationRecord
  belongs_to :user
  has_many :balances, dependent: :destroy
  
  validates :name, presence: true
  validates :account_type, presence: true
  
  enum :account_type, { savings: 0, checking: 1, credit_card: 2 }
  
  def current_balance
    balances.order(balance_date: :desc).first&.amount_cents || 0
  end
  
  def balance_2_months_ago
    balances.find_by(balance_date: 2.months.ago.beginning_of_month)&.amount_cents || 0
  end
  
  def balance_1_month_ago
    balances.find_by(balance_date: 1.month.ago.beginning_of_month)&.amount_cents || 0
  end
  
  def balance_current
    balances.find_by(balance_date: Date.today.beginning_of_month)&.amount_cents || 0
  end
  
  def current_snapshot_id
    balances.find_by(balance_date: Date.today.beginning_of_month)&.id
  end
end

