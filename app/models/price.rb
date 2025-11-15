class Price < ApplicationRecord
  belongs_to :holding
  
  validates :date, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  
  scope :by_date, -> { order(date: :desc) }
end

