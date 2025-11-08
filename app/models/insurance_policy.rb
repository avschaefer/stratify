class InsurancePolicy < ApplicationRecord
  belongs_to :user
  
  validates :policy_type, presence: true
  validates :provider, presence: true
  validates :coverage_amount, presence: true, numericality: { greater_than: 0 }
  validates :premium, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :term_years, presence: true, numericality: { greater_than: 0 }
  
  enum :status, { draft: 0, active: 1 }
  enum :policy_type, { life: 0, health: 1, auto: 2, home: 3 }
end

