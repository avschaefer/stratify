class SavingsAccount < ApplicationRecord
  belongs_to :user
  has_many :monthly_snapshots, dependent: :destroy
  
  validates :name, presence: true
  validates :account_type, presence: true
  
  enum :account_type, { savings: 0, checking: 1, credit_card: 2 }
  
  def current_balance
    monthly_snapshots.order(recorded_at: :desc).first&.balance || 0
  end
end

