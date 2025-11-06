class Portfolio < ApplicationRecord
  belongs_to :user
  
  validates :asset_type, presence: true
  validates :ticker, presence: true
  validates :purchase_date, presence: true
  validates :purchase_price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  
  enum :status, { draft: 0, active: 1 }
  
  def total_value
    purchase_price * quantity
  end
  
  def current_value(current_price = nil)
    current_price ||= purchase_price
    current_price * quantity
  end
end

