class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :holdings, dependent: :destroy
  
  validates :user_id, uniqueness: true  # has_one relationship
  
  def total_value
    holdings.sum { |h| h.current_value }
  end
  
  def total_cost_basis
    holdings.sum { |h| h.total_cost_basis }
  end
end

