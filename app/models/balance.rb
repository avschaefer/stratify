class Balance < ApplicationRecord
  belongs_to :account
  
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validates :balance_date, presence: true
  
  scope :by_date, -> { order(balance_date: :desc) }
end

