class Holding < ApplicationRecord
  belongs_to :portfolio
  has_many :prices, dependent: :destroy
  has_many :trades, dependent: :destroy
  
  validates :ticker, presence: true
  validates :shares, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :cost_basis_cents, numericality: { only_integer: true }, allow_nil: true
  
  def current_value(current_price_cents = nil)
    return 0 if shares.nil? || shares.zero?
    current_price_cents ||= latest_price&.amount_cents || 0
    (shares * current_price_cents / 100.0).round(2)
  end
  
  def latest_price
    prices.order(date: :desc).first
  end
  
  def total_cost_basis
    return 0 if cost_basis_cents.nil?
    cost_basis_cents / 100.0
  end
end

